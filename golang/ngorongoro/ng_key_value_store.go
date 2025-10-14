package ngorongoro

import (
	"github.com/syndtr/goleveldb/leveldb"
)

type KeyValueStore struct {
	db *leveldb.DB
}

func NewKeyValueStore() (*KeyValueStore, error) {
	db, err := leveldb.OpenFile("ngorongoro.db", nil)
	if err != nil {
		return nil, err
	}
	return &KeyValueStore{db: db}, nil
}

func (kvs *KeyValueStore) Put(key, value string) error {
	return kvs.db.Put([]byte(key), []byte(value), nil)
}

func (kvs *KeyValueStore) Get(key string) (string, error) {
	data, err := kvs.db.Get([]byte(key), nil)
	if err != nil {
		return "", err
	}
	return string(data), nil
}

func (kvs *KeyValueStore) Close() error {
	return kvs.db.Close()
}
