package rpc

import (
	"context"
	"testing"

	"github.com/heroiclabs/nakama-common/runtime"
)

func TestHelloGreetsCaller(t *testing.T) {
	ctx := context.WithValue(context.Background(), runtime.RUNTIME_CTX_USER_ID, "user-123")

	got, err := Hello(ctx, nil, nil, nil, "")
	if err != nil {
		t.Fatalf("Hello returned error: %v", err)
	}
	if want := `{"message":"Hello, user-123"}`; got != want {
		t.Errorf("Hello = %s, want %s", got, want)
	}
}

func TestHelloRejectsMissingUser(t *testing.T) {
	if _, err := Hello(context.Background(), nil, nil, nil, ""); err == nil {
		t.Fatal("Hello without a user ID should return an error")
	}
}
