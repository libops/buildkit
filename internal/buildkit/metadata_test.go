package buildkit

import (
	"os"
	"path/filepath"
	"testing"
)

func TestMetadataTagsMatchForkedVersioning(t *testing.T) {
	root := repoRoot(t)
	metadata, err := LoadMetadata(root)
	if err != nil {
		t.Fatal(err)
	}

	cases := []struct {
		image    string
		mode     string
		fallback string
		want     []string
	}{
		{image: "activemq5", mode: "fallback", fallback: "local", want: []string{"local-5"}},
		{image: "nginx-php83", mode: "fallback", fallback: "branch/name", want: []string{"branch-name-php8.3"}},
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
