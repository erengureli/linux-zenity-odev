#!/bin/bash

folder="datas"

depo=$folder"/depo.csv"
kullanici=$folder"/kullanici.csv"
log=$folder"/log.csv"

kullaniciID=-1 # giriş yaptıktan sonra kullanıcı id'sini tutacak

# .csv dosyalarının içinde bulunduğu klasörün kontrolü
if [ ! -d $folder ]; then
    mkdir $folder
fi

# .csv dosyaları var mı kontrol ediyoruz
if [ ! -f $depo ]; then
    touch $depo
fi
if [ ! -f $kullanici ]; then
    touch $kullanici
    echo "id,name,surname,role,password,passtry" > $kullanici
    echo "0,Eren,GÜRELİ,1,81dc9bdb52d04dc20036dbd8313ed055,0" >> $kullanici
fi
if [ ! -f $log ]; then
    touch $log
    echo "id,date,userId,product,log" > $log
    echo "0,$(date),-1,System,log.csv dosyası oluşturuldu." >> $log
fi

# Hızlı loglamak için fonksiyon - userId,product,log
logging(){
    echo "$(($(tail -n 1 $log | awk -F',' '{printf $1}' )+1)),$(date),$1,$2,$3" >> $log
}


# Giriş bilgilerinin zenity forms ile alınması
loginResult=$(zenity --forms \
    --title="Giriş Yapınız" \
    --text="Lütfen id ve şifrenizi giriniz" \
    --separator="," \
    --add-entry="ID" \
    --add-password="Şifre")

# Form iptal edildiyse programı kapatıyoruz
if [ $? -ne 0 ]; then
    exit 1
fi

# Forma girilen girdileri array'e dönüştürüyoruz
IFS="," read -ra loginData <<< $loginResult

# Bütün kullanıcıları kontorol ediyoruz
HEADER_SKIPPED=false
while IFS="," read -ra user; do
    # İlk elemanı atlıyoruz
    if [ $HEADER_SKIPPED = false ]; then
        HEADER_SKIPPED=true
        continue
    else
        # id'yi kontrol ediyoruz
        if [ ${loginData[0]} == ${user[0]} ]; then
            # deneme sayısını kontrol ediyoruz
            if [ ${user[5]} -lt 3 ]; then
                # şifrenin doğruluğunu kontrol ediyoruz
                if [ $(echo -n ${loginData[1]} | md5sum | awk '{print $1}') == ${user[4]} ]; then
                    kullaniciID=${user[0]}
                    break
                else
                    index=$((${user[0]}+2))
                    line=$(sed -n $index"p" $kullanici)
                    passTry=$(echo $line | awk -F',' '{print $6}')
                    newLine=$(echo $line | sed 's/.$/'$(($passTry+1))'/')

                    sed -i "${index}s/.*/$newLine/" $kullanici

                    logging "${user[0]}" "" "Hatalı şifre denemesi!"
                    zenity --error --text="Hatalı şifre!"
                    exit 1
                fi
            else
                zenity --error --text="Bu ID'li hesap kitlenmiştir. Lütfen yetkili biri tarafından kilidini açtırın!"
                exit 1
            fi
        fi
    fi 
done < $kullanici

# Bulunamadıysa kullaniciID değişkeni -1 kaldığından kontorl edip çıkış yapıyoruz
if [ $kullaniciID -lt 0 ]; then
    zenity --error --text="Bu ID'ye sahip bir kullanıcı bulunmamaktadır!"
    exit 1
fi

logging "${user[0]}" "" "Sisteme giriş yapıldı."
