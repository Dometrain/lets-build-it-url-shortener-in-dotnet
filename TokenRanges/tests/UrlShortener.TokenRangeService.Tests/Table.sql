CREATE TABLE "TokenRanges" (
                               "Id" SERIAL PRIMARY KEY,
                               "MachineIdentifier" VARCHAR(255) NOT NULL,
                               "Start" BIGINT NOT NULL UNIQUE,
                               "End" BIGINT NOT NULL UNIQUE
);