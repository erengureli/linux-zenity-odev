#!/bin/bash

depo="datas/depo.csv"
kullanici="datas/kullanici.csv"
log="datas/log.csv"

# .csv dosyaları var mı kontrol ediyoruz
if [ ! -f $depo ]; then
    touch $depo
fi

if [ ! -f $kullanici ]; then
    touch $kullanici
fi

if [ ! -f $log ]; then
    touch $log
fi
