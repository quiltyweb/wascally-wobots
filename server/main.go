package main

import (
	"context"
	"database/sql"

	"github.com/heroiclabs/nakama-common/runtime"

	"github.com/quiltyweb/wascally-wobots/server/rpc"
)

// InitModule is called by Nakama when it loads the plugin.
func InitModule(ctx context.Context, logger runtime.Logger, db *sql.DB, nk runtime.NakamaModule, initializer runtime.Initializer) error {
	if err := initializer.RegisterRpc("hello", rpc.Hello); err != nil {
		return err
	}

	logger.Info("module loaded")
	return nil
}
