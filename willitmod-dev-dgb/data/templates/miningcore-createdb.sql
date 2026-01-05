SET statement_timeout = 0;

CREATE TABLE shares
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	blockheight BIGINT NOT NULL,
	difficulty DOUBLE PRECISION NOT NULL,
	actualdifficulty DOUBLE PRECISION,
	networkdifficulty DOUBLE PRECISION NOT NULL,
	miner TEXT NOT NULL,
	worker TEXT,
	useragent TEXT,
	ipaddress TEXT,
	source TEXT,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_shares_poolid_created ON shares(poolid, created);
CREATE INDEX IX_shares_poolid_miner_created ON shares(poolid, miner, created);
CREATE INDEX IX_shares_poolid_miner_worker_created ON shares(poolid, miner, worker, created);

CREATE TABLE blocks
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	blockheight BIGINT NOT NULL,
	networkdifficulty DOUBLE PRECISION NOT NULL,
	status INT NOT NULL,
	type INT NOT NULL,
	transactionconfirmationdata TEXT,
	miner TEXT NOT NULL,
	worker TEXT,
	effort DOUBLE PRECISION NOT NULL,
	rewardamount DOUBLE PRECISION NOT NULL,
	info TEXT,
	hash TEXT NOT NULL,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_blocks_poolid_created ON blocks(poolid, created);
CREATE INDEX IX_blocks_poolid_height ON blocks(poolid, blockheight);

CREATE TABLE balances
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	address TEXT NOT NULL,
	amount DOUBLE PRECISION NOT NULL,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_balances_poolid_address ON balances(poolid, address);
CREATE INDEX IX_balances_poolid_created ON balances(poolid, created);

CREATE TABLE balance_changes
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	address TEXT NOT NULL,
	amount DOUBLE PRECISION NOT NULL,
	usage TEXT,
	tags TEXT,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_balance_changes_poolid_created ON balance_changes(poolid, created);
CREATE INDEX IX_balance_changes_poolid_address_created ON balance_changes(poolid, address, created);

CREATE TABLE miner_settings
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	address TEXT NOT NULL,
	paymentthreshold DOUBLE PRECISION NOT NULL,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_miner_settings_poolid_address ON miner_settings(poolid, address);

CREATE TABLE payments
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	coin TEXT NOT NULL,
	address TEXT NOT NULL,
	amount DOUBLE PRECISION NOT NULL,
	transactionconfirmationdata TEXT,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_payments_poolid_created ON payments(poolid, created);
CREATE INDEX IX_payments_poolid_address_created ON payments(poolid, address, created);

CREATE TABLE poolstats
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	connectedminers INT NOT NULL,
	poolhashrate DOUBLE PRECISION NOT NULL,
	networkhashrate DOUBLE PRECISION NOT NULL,
	networkdifficulty DOUBLE PRECISION NOT NULL,
	lastnetworkblocktime TIMESTAMP,
	blockheight BIGINT NOT NULL,
	connectedpeers INT NOT NULL,
	sharespersecond INT NOT NULL,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_poolstats_poolid_created ON poolstats(poolid, created);

CREATE TABLE minerstats
(
	id BIGSERIAL PRIMARY KEY NOT NULL,
	poolid TEXT NOT NULL,
	miner TEXT NOT NULL,
	hashrate DOUBLE PRECISION NOT NULL,
	sharespersecond INT NOT NULL,
	created TIMESTAMP NOT NULL
);

CREATE INDEX IX_minerstats_poolid_created ON minerstats(poolid, created);
CREATE INDEX IX_minerstats_poolid_miner_created ON minerstats(poolid, miner, created);
