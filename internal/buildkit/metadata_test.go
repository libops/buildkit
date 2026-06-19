package buildkit

import (
	"bytes"
	"os"
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
		{image: "drupal-php83", mode: "fallback", fallback: "branch/name", want: []string{"branch-name-php83"}},
		{image: "drupal-php83", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php83"}},
		{image: "drupal-php84", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php84"}},
		{image: "islandora-php84", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php84"}},
		{image: "wp-php84", mode: "version", fallback: "branch/name", want: []string{nginxTag + "-php84"}},
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
