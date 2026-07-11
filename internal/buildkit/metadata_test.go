package buildkit

import (
	"archive/zip"
	"bytes"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
)

func TestMetadataTagsMatchForkedVersioning(t *testing.T) {
	root := repoRoot(t)
	metadata, err := LoadMetadata(root)
	if err != nil {
		t.Fatal(err)
	}
	nginxVersion, err := dockerfileArgDefault(filepath.Join(root, "images", "nginx", "Dockerfile"), "NGINX_VERSION")
	if err != nil {
		t.Fatal(err)
	}
	nginxTag := "nginx-" + normalizeDockerTag(normalizeVersion("nginx", nginxVersion))

	cases := []struct {
		image    string
		mode     string
		fallback string
		want     []string
	}{
		{image: "activemq5", mode: "fallback", fallback: "local", want: []string{"local-5"}},
		{image: "archivesspace", mode: "fallback", fallback: "local", want: []string{"local"}},
		{image: "drupal-php83", mode: "fallback", fallback: "branch/name", want: []string{"branch-name-php83"}},
		{image: "drupal-php83", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php83"}},
		{image: "drupal-php84", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php84"}},
		{image: "islandora-php84", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php84"}},
		{image: "wp-php84", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php84"}},
		{image: "ojs-php83", mode: "version", fallback: "branch/name", want: []string{"3.5.0-5-php83", "3.5-php83", "3-php83", "php83"}},
		{image: "ojs-php84", mode: "version", fallback: "branch/name", want: []string{"3.5.0-5-php84", "3.5-php84", "3-php84", "php84", "latest-php84", "latest"}},
		{image: "omeka-s-php83", mode: "version", fallback: "branch/name", want: []string{"4.2.1-php83", "4.2-php83", "4-php83", "php83"}},
		{image: "omeka-s-php84", mode: "version", fallback: "branch/name", want: []string{"4.2.1-php84", "4.2-php84", "4-php84", "php84", "latest-php84", "latest"}},
		{image: "omeka-classic-php83", mode: "version", fallback: "branch/name", want: []string{"3.2.1-php83", "3.2-php83", "3-php83", "php83"}},
		{image: "omeka-classic-php84", mode: "version", fallback: "branch/name", want: []string{"3.2.1-php84", "3.2-php84", "3-php84", "php84", "latest-php84", "latest"}},
	}

	for _, tt := range cases {
		got, err := metadata.Tags(tt.image, tt.mode, tt.fallback)
		if err != nil {
			t.Fatalf("Tags(%s): %v", tt.image, err)
		}
		if len(got) != len(tt.want) {
			t.Fatalf("Tags(%s) = %v, want %v", tt.image, got, tt.want)
		}
		for index := range got {
			if got[index] != tt.want[index] {
				t.Fatalf("Tags(%s) = %v, want %v", tt.image, got, tt.want)
			}
		}
	}
}

func TestBundledPHPAppsDownloadVerifiedReleases(t *testing.T) {
	root := repoRoot(t)
	cases := []struct {
		image    string
		version  string
		checksum string
		dest     string
	}{
		{image: "ojs", version: "3.5.0-5", checksum: "fd59cb1add60ab4e56e40ed843ea43ff84af11f0b64c3940f2e03186ad11445e", dest: "/var/www/ojs"},
		{image: "omeka-s", version: "4.2.1", checksum: "cc27d1c7aca0209523d19aa285f4a08e29e34950dcc446951a7c1311de348e82", dest: "/var/www/omeka-s"},
		{image: "omeka-classic", version: "3.2.1", checksum: "2cb4d65511321cc5c009cb61516d9ed97378a800fc4a26eb46450c3c4ca230c2", dest: "/var/www/omeka-classic"},
	}

	for _, tt := range cases {
		dockerfile := filepath.Join(root, "images", tt.image, "Dockerfile")
		content, err := os.ReadFile(dockerfile)
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		for _, want := range []string{
			"SOFTWARE_VERSION=" + tt.version,
			"SHA256=\"" + tt.checksum + "\"",
			"download.sh",
			"--sha256 \"${SHA256}\"",
			"--strip",
			"--dest " + tt.dest,
		} {
			if !strings.Contains(got, want) {
				t.Errorf("%s missing %q", dockerfile, want)
			}
		}
	}
}

func TestMarketedApplicationImagesOverrideInheritedLicense(t *testing.T) {
	root := repoRoot(t)
	cases := map[string]string{
		"archivesspace":      "ECL-2.0",
		"archivesspace-solr": "Apache-2.0 AND ECL-2.0",
		"drupal":             "GPL-2.0-or-later",
		"ojs":                "GPL-3.0-only",
		"omeka-classic":      "GPL-3.0-or-later",
		"omeka-s":            "GPL-3.0-only",
		"wp":                 "GPL-2.0-or-later",
	}

	for image, license := range cases {
		dockerfile := filepath.Join(root, "images", image, "Dockerfile")
		content, err := os.ReadFile(dockerfile)
		if err != nil {
			t.Fatal(err)
		}
		want := `LABEL org.opencontainers.image.licenses="` + license + `"`
		if !strings.Contains(string(content), want) {
			t.Errorf("%s must override the inherited license with %q", dockerfile, license)
		}
	}
}

func TestBundledApplicationImagesPreserveLicenseTexts(t *testing.T) {
	root := repoRoot(t)
	cases := map[string]string{
		"archivesspace":      "cp /archivesspace/COPYING /usr/share/licenses/archivesspace/COPYING",
		"archivesspace-solr": "cp /tmp/archivesspace-release/archivesspace/COPYING /usr/share/licenses/archivesspace-solr/COPYING",
		"ojs":                "cp docs/COPYING /usr/share/licenses/ojs/COPYING",
		"omeka-classic":      "cp /var/www/omeka-classic/license.txt /usr/share/licenses/omeka-classic/license.txt",
		"omeka-s":            "cp /var/www/omeka-s/LICENSE /usr/share/licenses/omeka-s/LICENSE",
	}

	for image, want := range cases {
		dockerfile := filepath.Join(root, "images", image, "Dockerfile")
		content, err := os.ReadFile(dockerfile)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(content), want) {
			t.Errorf("%s must preserve the bundled application's license text at a standard path", dockerfile)
		}
	}
}

func TestCurlHealthchecksFailOnHTTPError(t *testing.T) {
	root := repoRoot(t)
	entries, err := os.ReadDir(filepath.Join(root, "images"))
	if err != nil {
		t.Fatal(err)
	}

	for _, entry := range entries {
		dockerfile := filepath.Join(root, "images", entry.Name(), "Dockerfile")
		content, err := os.ReadFile(dockerfile)
		if os.IsNotExist(err) {
			continue
		}
		if err != nil {
			t.Fatal(err)
		}
		for _, line := range strings.Split(string(content), "\n") {
			if strings.Contains(line, "HEALTHCHECK") && strings.Contains(line, "curl ") && !strings.Contains(line, "curl -f") {
				t.Errorf("%s healthcheck must make curl fail on HTTP errors: %s", dockerfile, line)
			}
		}
	}
}

func TestActiveMQHealthchecksKeepCredentialsOutOfArguments(t *testing.T) {
	root := repoRoot(t)
	for _, image := range []string{"activemq5", "activemq6"} {
		dockerfile := filepath.Join(root, "images", image, "Dockerfile")
		content, err := os.ReadFile(dockerfile)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(content), "HEALTHCHECK CMD activemq-healthcheck.sh") {
			t.Errorf("%s must delegate to the credential-safe healthcheck helper", dockerfile)
		}
		if strings.Contains(string(content), "HEALTHCHECK CMD curl") || strings.Contains(string(content), "cat /var/run/s6/container_environment/ACTIVEMQ_WEB_ADMIN_PASSWORD") {
			t.Errorf("%s must not expand web credentials in the healthcheck command", dockerfile)
		}

		helper := filepath.Join(root, "images", image, "rootfs", "usr", "local", "bin", "activemq-healthcheck.sh")
		helperContent, err := os.ReadFile(helper)
		if err != nil {
			t.Fatal(err)
		}
		got := string(helperContent)
		for _, want := range []string{
			"ACTIVEMQ_WEB_ADMIN_NAME ACTIVEMQ_WEB_ADMIN_PASSWORD",
			"umask 077",
			"chmod 0600",
			"trap 'rm -f",
			`curl --config "${curl_config}"`,
			`'fail'`,
		} {
			if !strings.Contains(got, want) {
				t.Errorf("%s missing %q", helper, want)
			}
		}
		if strings.Contains(got, `curl -u`) || strings.Contains(got, `curl --user`) {
			t.Errorf("%s passes credentials through curl arguments", helper)
		}

		for _, template := range []string{"credentials.properties.tmpl", "groups.properties.tmpl", "jetty-realm.properties.tmpl", "users.properties.tmpl"} {
			templateFile := filepath.Join(root, "images", image, "rootfs", "etc", "confd", "templates", template)
			templateContent, err := os.ReadFile(templateFile)
			if err != nil {
				t.Fatal(err)
			}
			rendered := string(templateContent)
			for _, want := range []string{`define "propertiesValueEscape"`, `replace $backslashes "\r" "\\r"`, `replace $carriageReturns "\n" "\\n"`, `replace $newlines "\t" "\\t"`, `replace $tabs " " "\\ "`} {
				if !strings.Contains(rendered, want) {
					t.Errorf("%s missing Java properties escaping contract %q", templateFile, want)
				}
			}
			if template != "credentials.properties.tmpl" {
				for _, want := range []string{`define "propertiesKeyEscape"`, `replace $spaces ":" "\\:"`, `replace $colons "=" "\\="`, `template "propertiesKeyEscape"`} {
					if !strings.Contains(rendered, want) {
						t.Errorf("%s missing Java properties key escaping contract %q", templateFile, want)
					}
				}
			}
		}
	}
}

func TestComposeEnvUsesCurrentVersionedImageForGenericAlias(t *testing.T) {
	root := repoRoot(t)
	metadata, err := LoadMetadata(root)
	if err != nil {
		t.Fatal(err)
	}

	resolver := imageResolver{
		metadata:    metadata,
		repository:  "libops",
		mode:        "fallback",
		fallbackTag: "local",
	}

	env := resolver.envFor("activemq5")
	if env["ACTIVEMQ"] != "libops/activemq:local-5" {
		t.Fatalf("ACTIVEMQ for activemq5 = %q", env["ACTIVEMQ"])
	}

	env = resolver.envFor("fcrepo7")
	if env["ACTIVEMQ"] != "libops/activemq:local-6" {
		t.Fatalf("ACTIVEMQ for fcrepo7 = %q", env["ACTIVEMQ"])
	}
	if env["FCREPO7"] != "libops/fcrepo:local-7" {
		t.Fatalf("FCREPO7 = %q", env["FCREPO7"])
	}

	env = resolver.envFor("drupal-php83")
	if env["DRUPAL"] != "libops/drupal:local-php83" {
		t.Fatalf("DRUPAL for drupal-php83 = %q", env["DRUPAL"])
	}
	if env["DRUPAL_PHP83"] != "libops/drupal:local-php83" {
		t.Fatalf("DRUPAL_PHP83 = %q", env["DRUPAL_PHP83"])
	}
}

func TestPlanSupportsLevelFourImages(t *testing.T) {
	root := repoRoot(t)
	metadata, err := LoadMetadata(root)
	if err != nil {
		t.Fatal(err)
	}

	plan, err := metadata.Plan("", "HEAD", "", true)
	if err != nil {
		t.Fatal(err)
	}
	if !containsString(plan.Level4, "islandora-php83") {
		t.Fatalf("level4 = %v, want islandora-php83", plan.Level4)
	}
	if !containsString(plan.Level4, "islandora-php84") {
		t.Fatalf("level4 = %v, want islandora-php84", plan.Level4)
	}
}

func TestPlannerImplementationPathsAreGlobal(t *testing.T) {
	global := []string{
		"cmd/buildkit/main.go",
		"go.mod",
		"go.sum",
		"internal/buildkit/metadata.go",
	}
	for _, path := range global {
		if !isGlobalPath(path) {
			t.Errorf("isGlobalPath(%q) = false, want true", path)
		}
	}

	if isGlobalPath("marketing/copy.md") {
		t.Error("unrelated documentation must not trigger a global image build")
	}
}

func TestMakefileNormalizesBranchWithoutShellReinterpolation(t *testing.T) {
	root := repoRoot(t)
	makefile := filepath.Join(root, "Makefile")
	content, err := os.ReadFile(makefile)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	if !strings.Contains(got, "rev-parse --abbrev-ref HEAD | sed -E") {
		t.Fatalf("%s must pipe the raw Git ref directly into normalization", makefile)
	}
	if strings.Contains(got, "BRANCH_RAW") {
		t.Fatalf("%s must not interpolate an untrusted raw branch into another shell command", makefile)
	}
	if !strings.Contains(got, `BRANCH="$(BRANCH)"`) {
		t.Fatalf("%s must quote the normalized branch passed to buildx bake", makefile)
	}
}

func TestBakeCacheRefsNormalizeSlashBranch(t *testing.T) {
	if _, err := exec.LookPath("docker"); err != nil {
		t.Skip("docker CLI is not available")
	}
	root := repoRoot(t)
	command := exec.Command("docker", "buildx", "bake", "--print", "activemq5-amd64")
	command.Dir = root
	command.Env = append(os.Environ(), "BRANCH=feature/foo")
	output, err := command.CombinedOutput()
	if err != nil {
		t.Skipf("docker buildx bake is not available: %v\n%s", err, output)
	}
	got := string(output)
	if !strings.Contains(got, "activemq5-feature-foo-amd64") {
		t.Fatalf("slash branch was not normalized in cache refs:\n%s", got)
	}
	if strings.Contains(got, "feature/foo") {
		t.Fatalf("slash branch leaked into a cache reference:\n%s", got)
	}
}

func TestUpdateSHAReadmeIsFailClosed(t *testing.T) {
	root := repoRoot(t)
	testScript := filepath.Join(root, "ci", "tests", "update-sha-readme.sh")
	command := exec.Command("bash", testScript)
	output, err := command.CombinedOutput()
	if err != nil {
		t.Fatalf("%s failed: %v\n%s", testScript, err, output)
	}
}

func TestPlanOutputUsesEmptyArraysForEmptyLevels(t *testing.T) {
	root := repoRoot(t)
	metadata, err := LoadMetadata(root)
	if err != nil {
		t.Fatal(err)
	}

	var output bytes.Buffer
	if err := runPlan(metadata, []string{"--image", "islandora-php83"}, &output); err != nil {
		t.Fatal(err)
	}
	got := output.String()
	for _, want := range []string{
		"level0=[]",
		"level1=[]",
		"level2=[]",
		"level3=[]",
		"test_level0=[]",
		"test_level1=[]",
		"test_level2=[]",
		"test_level3=[]",
		"level4=[\"islandora-php83\"]",
		"test_level4=[\"islandora-php83\"]",
	} {
		if !strings.Contains(got, want+"\n") {
			t.Fatalf("plan output missing %q:\n%s", want, got)
		}
	}
}

func TestMariaDBLongrunStartsServer(t *testing.T) {
	root := repoRoot(t)
	runFile := filepath.Join(root, "images", "mariadb11", "rootfs", "etc", "s6-overlay", "s6-rc.d", "mysqld", "run")
	content, err := os.ReadFile(runFile)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	if !strings.Contains(got, "/usr/bin/mariadbd") {
		t.Fatalf("%s must start the MariaDB server, got:\n%s", runFile, got)
	}
	if strings.Contains(got, "s6-setuidgid mysql mariadb --user mysql") {
		t.Fatalf("%s starts the MariaDB client instead of the server:\n%s", runFile, got)
	}
}

func TestOJSEnableBeaconTemplateUsesTruthyHelper(t *testing.T) {
	root := repoRoot(t)
	templateFile := filepath.Join(root, "images", "ojs", "rootfs", "etc", "confd", "templates", "config.inc.tmpl")
	content, err := os.ReadFile(templateFile)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	if strings.Contains(got, `if getenv "OJS_ENABLE_BEACON"`) {
		t.Fatalf("%s treats any non-empty OJS_ENABLE_BEACON value as On", templateFile)
	}
	if !strings.Contains(got, `define "booleanOnOff"`) || !strings.Contains(got, `enable_beacon = {{ template "booleanOnOff" (getenv "OJS_ENABLE_BEACON") }}`) {
		t.Fatalf("%s must render OJS_ENABLE_BEACON through the booleanOnOff helper", templateFile)
	}
}

func TestOJSConfigEscapesDoubleQuotedSecrets(t *testing.T) {
	root := repoRoot(t)
	templateFile := filepath.Join(root, "images", "ojs", "rootfs", "etc", "confd", "templates", "config.inc.tmpl")
	content, err := os.ReadFile(templateFile)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	for _, variable := range []string{"OJS_SECRET_KEY", "OJS_SALT", "OJS_API_KEY_SECRET"} {
		want := `template "doubleQuoteEscape" (getenv "` + variable + `")`
		if !strings.Contains(got, want) {
			t.Errorf("%s does not escape %s before rendering it in double quotes", templateFile, variable)
		}
	}
}

func TestOJSInstalledStateIsDurableAcrossConfdRendering(t *testing.T) {
	root := repoRoot(t)
	templateFile := filepath.Join(root, "images", "ojs", "rootfs", "etc", "confd", "templates", "config.inc.tmpl")
	content, err := os.ReadFile(templateFile)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	if strings.Contains(got, "installed = Off") {
		t.Fatalf("%s hardcodes the pre-install lifecycle state", templateFile)
	}
	if !strings.Contains(got, `installed = {{ template "booleanOnOff" (getenv "OJS_INSTALLED") }}`) {
		t.Fatalf("%s must render the reconciled OJS lifecycle state", templateFile)
	}

	for _, relative := range []string{
		"images/ojs/rootfs/etc/s6-overlay/s6-rc.d/confd-oneshot/dependencies.d/ojs-install-state",
		"images/ojs/rootfs/etc/s6-overlay/s6-rc.d/confd/dependencies.d/ojs-setup",
		"images/ojs/tests/ContinuousConfdPreservesInstalledState/docker-compose.yml",
	} {
		if _, err := os.Stat(filepath.Join(root, relative)); err != nil {
			t.Errorf("missing OJS lifecycle regression asset %s: %v", relative, err)
		}
	}

	setupFile := filepath.Join(root, "images", "ojs", "rootfs", "etc", "s6-overlay", "scripts", "ojs-setup.sh")
	setup, err := os.ReadFile(setupFile)
	if err != nil {
		t.Fatal(err)
	}
	stateIndex := strings.Index(string(setup), "/etc/s6-overlay/scripts/ojs-install-state.sh")
	renderIndex := strings.LastIndex(string(setup), "render_ojs_config")
	if stateIndex < 0 || renderIndex < 0 || stateIndex > renderIndex {
		t.Fatalf("%s must persist installed state before rerendering config", setupFile)
	}
}

func TestCredentialBearingConfdTemplatesAreNotWorldReadable(t *testing.T) {
	root := repoRoot(t)
	files := []string{
		"images/alpaca/rootfs/etc/confd/conf.d/alpaca.properties.toml",
		"images/ojs/rootfs/etc/confd/conf.d/config.inc.toml",
		"images/tomcat9/rootfs/etc/confd/conf.d/tomcat-users.toml",
		"images/tomcat11/rootfs/etc/confd/conf.d/tomcat-users.toml",
	}

	for _, relative := range files {
		content, err := os.ReadFile(filepath.Join(root, relative))
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(content), `mode = "0640"`) {
			t.Errorf("%s must render service-readable credentials without world access", relative)
		}
	}
}

func TestOmekaDatabaseTemplatesEscapeDoubleQuotedValues(t *testing.T) {
	root := repoRoot(t)
	cases := []struct {
		file   string
		fields []string
	}{
		{
			file:   filepath.Join(root, "images", "omeka-s", "rootfs", "etc", "confd", "templates", "database.ini.tmpl"),
			fields: []string{"DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD"},
		},
		{
			file:   filepath.Join(root, "images", "omeka-classic", "rootfs", "etc", "confd", "templates", "db.ini.tmpl"),
			fields: []string{"DB_HOST", "DB_PORT", "DB_NAME", "DB_USER", "DB_PASSWORD", "OMEKA_CLASSIC_TABLE_PREFIX"},
		},
	}

	for _, tt := range cases {
		content, err := os.ReadFile(tt.file)
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		if !strings.Contains(got, `define "doubleQuoteEscape"`) {
			t.Errorf("%s does not define doubleQuoteEscape", tt.file)
		}
		for _, field := range tt.fields {
			want := `template "doubleQuoteEscape" (getenv "` + field + `")`
			if !strings.Contains(got, want) {
				t.Errorf("%s does not escape %s", tt.file, field)
			}
		}
	}
}

func TestArchivesSpaceJDBCCredentialsAreURLAndRubyEscaped(t *testing.T) {
	root := repoRoot(t)
	templateFile := filepath.Join(root, "images", "archivesspace", "rootfs", "etc", "confd", "templates", "archivesspace.config.rb.tmpl")
	content, err := os.ReadFile(templateFile)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	for _, field := range []string{"$dbUser", "$dbPassword"} {
		want := `URI.encode_www_form_component('{{ template "sqlEscape" ` + field + ` }}')`
		if !strings.Contains(got, want) {
			t.Errorf("%s must Ruby-escape and URL-encode %s", templateFile, field)
		}
	}
	for _, unsafe := range []string{
		`&user={{ template "sqlEscape" $dbUser }}`,
		`&password={{ template "sqlEscape" $dbPassword }}`,
	} {
		if strings.Contains(got, unsafe) {
			t.Errorf("%s inserts a raw JDBC credential: %s", templateFile, unsafe)
		}
	}

	composeFile := filepath.Join(root, "images", "archivesspace", "tests", "ServiceHealthcheck", "docker-compose.yml")
	compose, err := os.ReadFile(composeFile)
	if err != nil {
		t.Fatal(err)
	}
	if strings.Count(string(compose), `DB_PASSWORD: "archive&=space%#password"`) != 2 {
		t.Errorf("%s must exercise URL-sensitive database credentials for both services", composeFile)
	}
}

func TestOmekaInstallersKeepAdminPasswordsOutOfCurlArguments(t *testing.T) {
	root := repoRoot(t)
	for _, image := range []string{"omeka-s", "omeka-classic"} {
		file := filepath.Join(root, "images", image, "rootfs", "etc", "s6-overlay", "scripts", image+"-setup.sh")
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		if strings.Contains(got, `--data-urlencode "password=${`) || strings.Contains(got, `-d "user[password`) {
			t.Errorf("%s passes an admin password value in curl argv", file)
		}
		for _, want := range []string{"umask 077", `>"${form_dir}/admin-password"`, `@${form_dir}/admin-password`} {
			if !strings.Contains(got, want) {
				t.Errorf("%s missing secure form handling %q", file, want)
			}
		}
	}
}

func TestBaseVaultSecretsBootstrap(t *testing.T) {
	root := repoRoot(t)

	dockerfile := filepath.Join(root, "images", "base", "Dockerfile")
	dockerfileContent, err := os.ReadFile(dockerfile)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"APP_UID=100",
		"LIBOPS_SITE_ID=",
		"VAULT_ADDR=",
		"VAULT_AUTH_METHOD=gcp",
		"VAULT_GCP_AUTH_TYPE=iam",
	} {
		if !strings.Contains(string(dockerfileContent), want) {
			t.Fatalf("%s missing %q", dockerfile, want)
		}
	}

	dependency := filepath.Join(root, "images", "base", "rootfs", "etc", "s6-overlay", "s6-rc.d", "container-environment", "dependencies.d", "vault-secrets")
	if _, err := os.Stat(dependency); err != nil {
		t.Fatalf("container-environment must depend on vault-secrets: %v", err)
	}

	containerEnvironment := filepath.Join(root, "images", "base", "rootfs", "etc", "s6-overlay", "scripts", "container-environment.sh")
	containerEnvironmentContent, err := os.ReadFile(containerEnvironment)
	if err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(containerEnvironmentContent), "GOOGLE_APPLICATION_CREDENTIALS") {
		t.Fatalf("%s must preserve GOOGLE_APPLICATION_CREDENTIALS as a file path", containerEnvironment)
	}
	for _, want := range []string{"umask 077", "chmod 0700 /var/run/s6/container_environment", "chmod 0600"} {
		if !strings.Contains(string(containerEnvironmentContent), want) {
			t.Fatalf("%s must protect imported secret values with %q", containerEnvironment, want)
		}
	}

	script := filepath.Join(root, "images", "base", "rootfs", "etc", "s6-overlay", "scripts", "vault-secrets.sh")
	scriptContent, err := os.ReadFile(script)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range []string{
		"GOOGLE_APPLICATION_CREDENTIALS",
		"private_key_id",
		"openssl dgst -sha256 -sign",
		"secret-organization",
		"secret-project",
		"secret-site",
		"chmod 0400",
		"chown \"${app_uid}:0\"",
		`if [[ "${name}" = "DB_ROOT_PASSWORD" ]]`,
		"chown 0:0",
	} {
		if !strings.Contains(string(scriptContent), want) {
			t.Fatalf("%s missing %q", script, want)
		}
	}
}

func TestContainerEnvironmentEscapesExeclineValues(t *testing.T) {
	root := repoRoot(t)
	file := filepath.Join(root, "images", "base", "rootfs", "etc", "s6-overlay", "scripts", "container-environment.sh")
	content, err := os.ReadFile(file)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	if !strings.Contains(got, `define "execlineEscape"`) {
		t.Fatalf("%s must define an execline value escape helper", file)
	}
	if !strings.Contains(got, `template \"execlineEscape\"`) {
		t.Fatalf("%s must escape values before generating the execline import script", file)
	}
}

func TestWithContEnvApplicationLongrunsDropDatabaseRootPassword(t *testing.T) {
	root := repoRoot(t)
	files := []string{
		filepath.Join(root, "images", "activemq5", "rootfs", "etc", "s6-overlay", "s6-rc.d", "activemq", "run"),
		filepath.Join(root, "images", "activemq6", "rootfs", "etc", "s6-overlay", "s6-rc.d", "activemq", "run"),
		filepath.Join(root, "images", "alpaca", "rootfs", "etc", "s6-overlay", "s6-rc.d", "alpaca", "run"),
		filepath.Join(root, "images", "archivesspace", "rootfs", "usr", "local", "bin", "archivesspace-startup.sh"),
		filepath.Join(root, "images", "solr9", "rootfs", "etc", "s6-overlay", "s6-rc.d", "solr", "run"),
		filepath.Join(root, "images", "solr10", "rootfs", "etc", "s6-overlay", "s6-rc.d", "solr", "run"),
		filepath.Join(root, "images", "tomcat9", "rootfs", "etc", "s6-overlay", "s6-rc.d", "tomcat", "run"),
		filepath.Join(root, "images", "tomcat11", "rootfs", "etc", "s6-overlay", "s6-rc.d", "tomcat", "run"),
	}

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		unsetIndex := strings.Index(got, "unset DB_ROOT_PASSWORD")
		execIndex := strings.LastIndex(got, "exec ")
		if unsetIndex < 0 || execIndex < 0 || unsetIndex > execIndex {
			t.Errorf("%s must unset DB_ROOT_PASSWORD before its final exec", file)
		}
	}
}

func TestApplicationDatabaseBootstrapIsExplicit(t *testing.T) {
	root := repoRoot(t)
	baseDockerfile := filepath.Join(root, "images", "base", "Dockerfile")
	content, err := os.ReadFile(baseDockerfile)
	if err != nil {
		t.Fatal(err)
	}
	base := string(content)
	if !strings.Contains(base, "DB_BOOTSTRAP_ENABLED=false") {
		t.Fatalf("%s must disable application-side database bootstrap by default", baseDockerfile)
	}
	if strings.Contains(base, "DB_ROOT_PASSWORD=password") {
		t.Fatalf("%s must not provide a placeholder database root password", baseDockerfile)
	}

	files := []string{
		filepath.Join(root, "images", "drupal", "rootfs", "etc", "s6-overlay", "scripts", "install.sh"),
		filepath.Join(root, "images", "ojs", "rootfs", "etc", "s6-overlay", "scripts", "ojs-setup.sh"),
		filepath.Join(root, "images", "omeka-s", "rootfs", "etc", "s6-overlay", "scripts", "omeka-s-setup.sh"),
		filepath.Join(root, "images", "omeka-classic", "rootfs", "etc", "s6-overlay", "scripts", "omeka-classic-setup.sh"),
		filepath.Join(root, "images", "wp", "rootfs", "etc", "s6-overlay", "scripts", "wordpress-setup.sh"),
		filepath.Join(root, "images", "archivesspace", "rootfs", "usr", "local", "bin", "archivesspace-startup.sh"),
		filepath.Join(root, "images", "fcrepo6", "rootfs", "etc", "s6-overlay", "scripts", "fcrepo-setup.sh"),
		filepath.Join(root, "images", "fcrepo7", "rootfs", "etc", "s6-overlay", "scripts", "fcrepo-setup.sh"),
	}
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(content), "database_bootstrap_if_enabled") {
			t.Errorf("%s must gate database creation behind the explicit bootstrap helper", file)
		}
	}
}

func TestMarketedApplicationImagesDoNotShipKnownCredentials(t *testing.T) {
	root := repoRoot(t)
	images := []string{"archivesspace", "drupal", "ojs", "omeka-s", "omeka-classic", "wp"}
	banned := []string{
		"DB_PASSWORD=changeme",
		"DRUPAL_DEFAULT_ACCOUNT_PASSWORD=password",
		"DRUPAL_DEFAULT_SALT=9PPaL0",
		"OJS_SALT=changeme",
		"OJS_API_KEY_SECRET=changeme",
		"OJS_SECRET_KEY=changeme",
		"OJS_ADMIN_PASSWORD=changeme",
		"OMEKA_S_ADMIN_PASSWORD=changeme",
		"OMEKA_CLASSIC_ADMIN_PASSWORD=changeme",
		"WORDPRESS_ADMIN_PASSWORD=changeme",
		"WORDPRESS_AUTH_KEY=changeme",
		"WORDPRESS_NONCE_SALT=changeme",
	}
	for _, image := range images {
		file := filepath.Join(root, "images", image, "Dockerfile")
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		for _, value := range banned {
			if strings.Contains(got, value) {
				t.Errorf("%s ships known credential %q", file, value)
			}
		}
	}
}

func TestNetworkServicesDoNotShipKnownCredentials(t *testing.T) {
	root := repoRoot(t)
	cases := []struct {
		file   string
		banned []string
	}{
		{file: filepath.Join(root, "images", "activemq5", "Dockerfile"), banned: []string{"ACTIVEMQ_PASSWORD=password", "ACTIVEMQ_WEB_ADMIN_PASSWORD=password"}},
		{file: filepath.Join(root, "images", "activemq6", "Dockerfile"), banned: []string{"ACTIVEMQ_PASSWORD=password", "ACTIVEMQ_WEB_ADMIN_PASSWORD=password"}},
		{file: filepath.Join(root, "images", "alpaca", "Dockerfile"), banned: []string{"ALPACA_JMS_PASSWORD=password"}},
		{file: filepath.Join(root, "images", "base", "Dockerfile"), banned: []string{"DB_PASSWORD=password", "JWT_ADMIN_TOKEN=islandora"}},
		{file: filepath.Join(root, "images", "fcrepo6", "Dockerfile"), banned: []string{"DB_PASSWORD=password"}},
		{file: filepath.Join(root, "images", "fcrepo7", "Dockerfile"), banned: []string{"DB_PASSWORD=password"}},
		{file: filepath.Join(root, "images", "tomcat9", "Dockerfile"), banned: []string{"TOMCAT_ADMIN_PASSWORD=password", "TOMCAT_MANAGER_REMOTE_ADDRESS_VALVE=^.*$", "TOMCAT_MANAGER_REMOTE_ADDRESS_VALVE=^(127[.]|::1$)"}},
		{file: filepath.Join(root, "images", "tomcat11", "Dockerfile"), banned: []string{"TOMCAT_ADMIN_PASSWORD=password", "TOMCAT_MANAGER_REMOTE_ADDRESS_VALVE=^.*$", "TOMCAT_MANAGER_REMOTE_ADDRESS_VALVE=^(127[.]|::1$)"}},
	}
	for _, tt := range cases {
		content, err := os.ReadFile(tt.file)
		if err != nil {
			t.Fatal(err)
		}
		for _, value := range tt.banned {
			if strings.Contains(string(content), value) {
				t.Errorf("%s ships known credential %q", tt.file, value)
			}
		}
	}
}

func TestOJSSetupInstallsAgainstExternalDatabaseHost(t *testing.T) {
	root := repoRoot(t)
	library := filepath.Join(root, "images", "base", "rootfs", "usr", "local", "share", "libops", "database.sh")
	environmentLibrary := filepath.Join(root, "images", "base", "rootfs", "usr", "local", "share", "libops", "environment.sh")
	setup := filepath.Join(root, "images", "ojs", "rootfs", "etc", "s6-overlay", "scripts", "ojs-setup.sh")
	harness := `
set -euo pipefail
export OJS_SETUP_LIBRARY_ONLY=true
export LIBOPS_DATABASE_LIBRARY="$1"
export LIBOPS_ENVIRONMENT_LIBRARY="$2"
source "$3"
calls=$(mktemp)
mysql_create_database() { printf 'bootstrap\n' >>"${calls}"; }
wait_for_database() { printf 'wait\n' >>"${calls}"; }
check_ojs_installed() { printf 'check\n' >>"${calls}"; return 1; }
install_ojs() { printf 'install\n' >>"${calls}"; }
export DB_HOST=external-database.example
export DB_BOOTSTRAP_ENABLED=false
export OJS_ADMIN_PASSWORD=test-admin-password
setup_ojs_database
test "$(cat "${calls}")" = $'wait\ncheck\ninstall'
`
	command := exec.Command("bash", "-c", harness, "bash", library, environmentLibrary, setup)
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("external database setup stub failed: %v\n%s", err, output)
	}
}

func TestNonDatabaseLongRunsDropDatabaseRootPassword(t *testing.T) {
	root := repoRoot(t)
	files := []string{
		filepath.Join(root, "images", "base", "rootfs", "etc", "s6-overlay", "s6-rc.d", "confd", "run"),
		filepath.Join(root, "images", "nginx", "rootfs", "etc", "s6-overlay", "s6-rc.d", "nginx", "run"),
		filepath.Join(root, "images", "php83", "rootfs", "etc", "s6-overlay", "s6-rc.d", "fpm", "run"),
		filepath.Join(root, "images", "php84", "rootfs", "etc", "s6-overlay", "s6-rc.d", "fpm", "run"),
		filepath.Join(root, "images", "scyllaridae", "rootfs", "etc", "s6-overlay", "s6-rc.d", "scyllaridae", "run"),
	}
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(content), "unset DB_ROOT_PASSWORD") && !strings.Contains(string(content), "unexport DB_ROOT_PASSWORD") {
			t.Errorf("%s retains DB_ROOT_PASSWORD in a non-database longrun", file)
		}
	}
}

func TestPHPLongRunsDropSetupOnlyAdminPasswords(t *testing.T) {
	root := repoRoot(t)
	files := []string{
		filepath.Join(root, "images", "nginx", "rootfs", "etc", "s6-overlay", "s6-rc.d", "nginx", "run"),
		filepath.Join(root, "images", "php83", "rootfs", "etc", "s6-overlay", "s6-rc.d", "fpm", "run"),
		filepath.Join(root, "images", "php84", "rootfs", "etc", "s6-overlay", "s6-rc.d", "fpm", "run"),
	}
	variables := []string{
		"DRUPAL_DEFAULT_ACCOUNT_PASSWORD",
		"OJS_ADMIN_PASSWORD",
		"OMEKA_CLASSIC_ADMIN_PASSWORD",
		"OMEKA_S_ADMIN_PASSWORD",
		"WORDPRESS_ADMIN_PASSWORD",
	}
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		for _, variable := range variables {
			if !strings.Contains(got, variable) {
				t.Errorf("%s retains setup-only %s", file, variable)
			}
		}
	}
}

func TestWordPressAdminPasswordUsesPromptInput(t *testing.T) {
	root := repoRoot(t)
	file := filepath.Join(root, "images", "wp", "rootfs", "etc", "s6-overlay", "scripts", "wordpress-setup.sh")
	content, err := os.ReadFile(file)
	if err != nil {
		t.Fatal(err)
	}
	got := string(content)
	if strings.Contains(got, `--admin_password="${WORDPRESS_ADMIN_PASSWORD}"`) {
		t.Fatalf("%s exposes the administrator password in wp-cli argv", file)
	}
	if !strings.Contains(got, `--prompt=admin_password`) || !strings.Contains(got, `printf '%s\n' "${WORDPRESS_ADMIN_PASSWORD}"`) {
		t.Fatalf("%s must provide the administrator password through wp-cli prompt input", file)
	}
}

func TestTomcatManagerDefaultAllowsOnlyLoopback(t *testing.T) {
	root := repoRoot(t)
	for _, version := range []string{"tomcat9", "tomcat11"} {
		file := filepath.Join(root, "images", version, "Dockerfile")
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(content), "TOMCAT_MANAGER_REMOTE_ADDRESS_VALVE=^(127[.].*|::1)$") {
			t.Errorf("%s does not restrict the manager valve to complete loopback addresses", file)
		}

		templateFile := filepath.Join(root, "images", version, "rootfs", "etc", "confd", "templates", "tomcat-users.xml.tmpl")
		templateContent, err := os.ReadFile(templateFile)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(templateContent), `template "xmlAttributeEscape" (getenv "TOMCAT_ADMIN_PASSWORD")`) {
			t.Errorf("%s does not XML-escape the administrator password", templateFile)
		}
		if strings.Contains(string(templateContent), `$escaped = replace`) {
			t.Errorf("%s uses template reassignment unsupported by the bundled confd", templateFile)
		}

		readmeFile := filepath.Join(root, "images", version, "README.md")
		readmeContent, err := os.ReadFile(readmeFile)
		if err != nil {
			t.Fatal(err)
		}
		for _, want := range []string{"-p 127.0.0.1:8080:8080", `--env TOMCAT_MANAGER_REMOTE_ADDRESS_VALVE='.*'`} {
			if !strings.Contains(string(readmeContent), want) {
				t.Errorf("%s local manager example missing %q", readmeFile, want)
			}
		}
	}
}

func TestDrupalInstalledQueryDoesNotInterpolateDatabaseName(t *testing.T) {
	root := repoRoot(t)
	library := filepath.Join(root, "images", "base", "rootfs", "usr", "local", "share", "libops", "database.sh")
	environmentLibrary := filepath.Join(root, "images", "base", "rootfs", "usr", "local", "share", "libops", "environment.sh")
	setup := filepath.Join(root, "images", "drupal", "rootfs", "etc", "s6-overlay", "scripts", "install.sh")
	harness := `
set -euo pipefail
export DRUPAL_SETUP_LIBRARY_ONLY=true
export LIBOPS_DATABASE_LIBRARY="$1"
export LIBOPS_ENVIRONMENT_LIBRARY="$2"
export DB_NAME="external-db-'quoted"
source "$3"
query=$(mysql_count_query)
grep -Fq 'WHERE table_schema = DATABASE();' <<<"${query}"
if grep -Fq "${DB_NAME}" <<<"${query}"; then exit 1; fi
`
	command := exec.Command("bash", "-c", harness, "bash", library, environmentLibrary, setup)
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("Drupal installed query interpolation test failed: %v\n%s", err, output)
	}
}

func TestCommandHelpersDoNotEvalArguments(t *testing.T) {
	root := repoRoot(t)
	files := []string{
		filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "download.sh"),
		filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "create-service-user.sh"),
		filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "cleanup.sh"),
		filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "confd-import-environment.sh"),
		filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "wait-for-open-port.sh"),
		filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "confd-render-templates.sh"),
		filepath.Join(root, "images", "drupal", "rootfs", "usr", "local", "bin", "install-drupal-site.sh"),
	}
	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		if strings.Contains(string(content), "eval "+"set --") {
			t.Errorf("%s evaluates reconstructed command-line arguments", file)
		}

		marker := filepath.Join(t.TempDir(), "argument-was-executed")
		malicious := `space "$(touch ` + marker + `)" 'quoted'`
		command := exec.Command("bash", file, "--help", malicious)
		command.Env = append(os.Environ(), "DOWNLOAD_CACHE_DIRECTORY=/tmp")
		_ = command.Run()
		if _, err := os.Stat(marker); !os.IsNotExist(err) {
			t.Errorf("%s executed a command embedded in an argument", file)
		}
	}
}

func TestDatabaseHelpersDoNotForwardPasswordsInArguments(t *testing.T) {
	root := repoRoot(t)
	cases := []struct {
		file   string
		banned []string
	}{
		{
			file: filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "create-database.sh"),
			banned: []string{
				`--password "${PASSWORD}"`,
			},
		},
		{
			file: filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "execute-sql-file.sh"),
			banned: []string{
				`--password "${PASSWORD}"`,
				`--password="${PASSWORD}"`,
			},
		},
		{
			file: filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "wait-for-database.sh"),
			banned: []string{
				`--password="${PASSWORD}"`,
			},
		},
	}
	for _, tt := range cases {
		content, err := os.ReadFile(tt.file)
		if err != nil {
			t.Fatal(err)
		}
		for _, banned := range tt.banned {
			if strings.Contains(string(content), banned) {
				t.Errorf("%s exposes a password through child argv: %s", tt.file, banned)
			}
		}
	}
}

func TestDrupalInstallersKeepDatabasePasswordsOutOfArguments(t *testing.T) {
	root := repoRoot(t)
	primary := filepath.Join(root, "images", "drupal", "rootfs", "etc", "s6-overlay", "scripts", "install.sh")
	helper := filepath.Join(root, "images", "drupal", "rootfs", "usr", "local", "bin", "install-drupal-site.sh")
	islandora := filepath.Join(root, "images", "islandora", "rootfs", "etc", "islandora", "utilities.sh")

	for _, file := range []string{primary, helper, islandora} {
		content, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		for _, banned := range []string{"--db-url=", "--db-password", "--account-pass="} {
			if strings.Contains(got, banned) {
				t.Errorf("%s still forwards a credential using %q", file, banned)
			}
		}
	}

	helperContent, err := os.ReadFile(helper)
	if err != nil {
		t.Fatal(err)
	}
	got := string(helperContent)
	for _, want := range []string{
		`rawurlencode((string) getenv("LIBOPS_DRUPAL_URI_COMPONENT"))`,
		`DRUSH_COMMAND_SITE_INSTALL_OPTIONS_DB_URL="${drush_database_url}"`,
		`DB_PASSWORD=${LIBOPS_DRUPAL_INSTALL_DB_PASSWORD:-}`,
	} {
		if !strings.Contains(got, want) {
			t.Errorf("%s missing %q", helper, want)
		}
	}
}

func TestGenericDrupalInstallerEncodesDatabaseURLWithoutArgumentExposure(t *testing.T) {
	root := repoRoot(t)
	helper := filepath.Join(root, "images", "drupal", "rootfs", "usr", "local", "bin", "install-drupal-site.sh")
	binDir := t.TempDir()
	outputFile := filepath.Join(t.TempDir(), "drush-db-url")
	rawPassword := `p"a\ss'word&+=:/?#%`

	executeSQL := filepath.Join(binDir, "execute-sql-file.sh")
	if err := os.WriteFile(executeSQL, []byte("#!/bin/sh\nprintf '0\\n'\n"), 0o755); err != nil {
		t.Fatal(err)
	}
	drush := filepath.Join(binDir, "drush")
	drushScript := `#!/bin/sh
for argument do
  case "${argument}" in
    *"${EXPECTED_RAW_PASSWORD}"*) exit 42 ;;
  esac
done
printf '%s\n' "${DRUSH_COMMAND_SITE_INSTALL_OPTIONS_DB_URL}" >"${DRUSH_OUTPUT}"
`
	if err := os.WriteFile(drush, []byte(drushScript), 0o755); err != nil {
		t.Fatal(err)
	}

	command := exec.Command("bash", helper,
		"--host", "database",
		"--port", "3306",
		"--db-user", "user@name",
		"--db-name", "drupal/name",
		"standard", "--sites-subdir=default",
	)
	command.Env = append(os.Environ(),
		"PATH="+binDir+":"+os.Getenv("PATH"),
		"LIBOPS_DRUPAL_INSTALL_DB_PASSWORD="+rawPassword,
		"EXPECTED_RAW_PASSWORD="+rawPassword,
		"DRUSH_OUTPUT="+outputFile,
	)
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("generic Drupal installer failed: %v\n%s", err, output)
	}
	url, err := os.ReadFile(outputFile)
	if err != nil {
		t.Fatal(err)
	}
	want := "mysql://user%40name:p%22a%5Css%27word%26%2B%3D%3A%2F%3F%23%25@database:3306/drupal%2Fname\n"
	if string(url) != want {
		t.Fatalf("encoded Drush database URL = %q, want %q", url, want)
	}
}

func TestPHPRuntimeSecretConfigsAreGroupReadableOnly(t *testing.T) {
	root := repoRoot(t)
	files := []string{
		"images/drupal/rootfs/etc/confd/conf.d/drupal.libops.settings.toml",
		"images/wp/rootfs/etc/confd/conf.d/wordpress.application.toml",
	}
	for _, relative := range files {
		content, err := os.ReadFile(filepath.Join(root, relative))
		if err != nil {
			t.Fatal(err)
		}
		got := string(content)
		if !strings.Contains(got, "uid = 0\ngid = 101\nmode = \"0640\"") {
			t.Errorf("%s must render root-owned, nginx-group-readable runtime secrets", relative)
		}
	}

	developmentScript, err := os.ReadFile(filepath.Join(root, "images", "islandora", "rootfs", "etc", "s6-overlay", "scripts", "development-environment.sh"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(developmentScript), "groupmod") {
		t.Error("Islandora development UID remapping must preserve the stable nginx GID used by runtime secret configs")
	}
}

func TestVersionedImageReadmesMatchDockerfiles(t *testing.T) {
	root := repoRoot(t)
	images := []string{"alpaca", "mariadb11", "tomcat11"}
	for _, image := range images {
		version, err := dockerfileArgDefault(filepath.Join(root, "images", image, "Dockerfile"), "SOFTWARE_VERSION")
		if err != nil {
			t.Fatal(err)
		}
		version = normalizeVersion(image, version)
		readme := filepath.Join(root, "images", image, "README.md")
		content, err := os.ReadFile(readme)
		if err != nil {
			t.Fatal(err)
		}
		if !strings.Contains(string(content), "version "+version+".") {
			t.Errorf("%s does not document Dockerfile SOFTWARE_VERSION %s", readme, version)
		}
	}
}

func TestDownloadZipStripRequiresOneTopLevelDirectory(t *testing.T) {
	root := repoRoot(t)
	script := filepath.Join(root, "images", "base", "rootfs", "usr", "local", "bin", "download.sh")

	invalidZip := filepath.Join(t.TempDir(), "invalid.zip")
	writeTestZip(t, invalidZip, map[string]string{
		"first/file.txt":  "first",
		"second/file.txt": "second",
	})
	invalidDest := t.TempDir()
	command := exec.Command("bash", "-c", `set -euo pipefail; export DOWNLOAD_LIBRARY_ONLY=true; source "$1"; STRIP=true; REMOVE=(); unpack "$2" "$3"`, "bash", script, invalidZip, invalidDest)
	output, err := command.CombinedOutput()
	if err == nil || !strings.Contains(string(output), "exactly one top-level directory") {
		t.Fatalf("multi-root ZIP was not rejected safely: err=%v output=%s", err, output)
	}

	validZip := filepath.Join(t.TempDir(), "valid.zip")
	writeTestZip(t, validZip, map[string]string{"release/file.txt": "payload"})
	validDest := t.TempDir()
	command = exec.Command("bash", "-c", `set -euo pipefail; export DOWNLOAD_LIBRARY_ONLY=true; source "$1"; STRIP=true; REMOVE=(); unpack "$2" "$3"`, "bash", script, validZip, validDest)
	if output, err := command.CombinedOutput(); err != nil {
		t.Fatalf("single-root ZIP strip failed: %v\n%s", err, output)
	}
	content, err := os.ReadFile(filepath.Join(validDest, "file.txt"))
	if err != nil {
		t.Fatal(err)
	}
	if string(content) != "payload" {
		t.Fatalf("stripped ZIP payload = %q", content)
	}
}

func writeTestZip(t *testing.T, path string, entries map[string]string) {
	t.Helper()
	file, err := os.Create(path)
	if err != nil {
		t.Fatal(err)
	}
	archive := zip.NewWriter(file)
	for name, content := range entries {
		entry, err := archive.Create(name)
		if err != nil {
			t.Fatal(err)
		}
		if _, err := io.WriteString(entry, content); err != nil {
			t.Fatal(err)
		}
	}
	if err := archive.Close(); err != nil {
		t.Fatal(err)
	}
	if err := file.Close(); err != nil {
		t.Fatal(err)
	}
}

func repoRoot(t *testing.T) string {
	t.Helper()
	dir, err := os.Getwd()
	if err != nil {
		t.Fatal(err)
	}
	for {
		if _, err := os.Stat(filepath.Join(dir, "docker-bake.hcl")); err == nil {
			return dir
		}
		parent := filepath.Dir(dir)
		if parent == dir {
			t.Fatal("could not find docker-bake.hcl")
		}
		dir = parent
	}
}
