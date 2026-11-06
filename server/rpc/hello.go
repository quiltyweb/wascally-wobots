// Package rpc holds the RPCs that clients can call.
package rpc

import (
	"context"
	"database/sql"
	"encoding/json"

	"github.com/heroiclabs/nakama-common/runtime"
)

// gRPC status code returned when the caller has no user ID.
const codeUnauthenticated = 16

type helloResponse struct {
	Message string `json:"message"`
}

// Hello greets the calling user by their user ID.
func Hello(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, payload string) (string, error) {
	userID, ok := ctx.Value(runtime.RUNTIME_CTX_USER_ID).(string)
	if !ok || userID == "" {
		return "", runtime.NewError("hello must be called by an authenticated user", codeUnauthenticated)
	}

	out, err := json.Marshal(helloResponse{Message: "Hello, " + userID})
	if err != nil {
		return "", err
	}
	return string(out), nil
}
