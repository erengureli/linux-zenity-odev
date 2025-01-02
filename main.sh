#!/bin/bash

folder="datas"

depo=$folder"/depo.csv"
kullanici=$folder"/kullanici.csv"
log=$folder"/log.csv"

# .csv dosyaları ve bulunması gereken klasör var mı
if [ ! -d $folder ]; then
    mkdir $folder
fi
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
unset folder

# Hızlı loglamak için fonksiyon -> userId product log
logging(){
    lastLogId=$(tail -n 1 $log | awk -F',' '{printf $1}')
    if [[ "$lastLogId" =~ ^[0-9]+$ ]]; then
        echo "$(($lastLogId+1)),$(date),$1,$2,$3" >> $log
    else
        echo "0,$(date),$1,$2,$3" >> $log
    fi
    unset lastLogId
}

# Giriş bilgilerinin zenity forms ile alınması
loginData=$(zenity --forms \
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
IFS="," read -ra loginData <<< $loginData

# Bütün kullanıcıları kontorol ediyoruz
HEADER_SKIPPED=false
USER_FIND=false
while IFS="," read -ra user; do
    # İlk elemanı atlıyoruz
    if [ $HEADER_SKIPPED = false ]; then
        HEADER_SKIPPED=true
        continue
    else
        # id'yi kontrol ediyoruz
        if [ "${loginData[0]}" == "${user[0]}" ]; then
            USER_FIND=true
            # deneme sayısını kontrol ediyoruz
            if [ ${user[5]} -lt 3 ]; then
                # şifrenin doğruluğunu kontrol ediyoruz
                if [ "$(echo -n ${loginData[1]} | md5sum | awk '{print $1}')" == "${user[4]}" ]; then
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
if [ $USER_FIND = false ]; then
    zenity --error --text="Bu ID'ye sahip bir kullanıcı bulunmamaktadır!"
    exit 1
fi

# Gerekli olmayan verileri temizliyoruz
unset HEADER_SKIPPED
unset USER_FIND
unset loginData

# Giriş yapan kişiyi logluyoruz
logging "${user[0]}" "" "Sisteme giriş yapıldı."

progress(){
    (
        echo "10" ; sleep 0.3
        echo "# $3" ; sleep 0.3
        echo "20" ; sleep 0.3
        echo "40" ; sleep 0.3
        echo "# $4" ; sleep 0.3
        echo "75" ; sleep 0.3
        echo "# $5" ; sleep 0.3
        echo "100" ; sleep 0.3
    ) |
    zenity --progress \
        --title="$1" \
        --text="$2" \
        --percentage=0
}

# Sonsuz döngü içinde işlem yapıyoruz
while true; do

    # Admin ise farklı, user ise farklı arayüz çıkacak
    if [ ${user[3]} -eq 1 ]; then
        choice=$(zenity --list \
            --title="Admin Ana Menü" \
            --text="Yapmak istediğiniz işlemi seçiniz." \
            --height=350 \
            --column="İşlem" \
            "Ürün Ekle" \
            "Ürün Listele" \
            "Ürün Güncelle" \
            "Ürün Sil" \
            "Rapor Al" \
            "Kullanıcı Yönetimi" \
            "Program Yönetii" \
            "Çıkış Yap" )
    else
        choice=$(zenity --list \
            --title="Kullanıcı Ana Menü" \
            --text="Yapmak istediğiniz işlemi seçiniz." \
            --column="İşlem" \
            "Ürün Listele" \
            "Rapor Al" \
            "Çıkış Yap" )
    fi

    # Seçilen işlem için switch case
    case $choice in
        "Çıkış Yap" | "")
            exit 1
            ;;
        "Ürün Ekle")
            ;;
        "Ürün Listele")
            ;;
        "Ürün Güncelle")
            ;;
        "Ürün Sil")
            ;;
        "Rapor Al")
            ;;
        "Kullanıcı Yönetimi")
            if [ ${user[3]} -eq 1 ]; then
                choice=$(zenity --list \
                    --title="Kullanıcı Yönetimi" \
                    --text="Yapmak istediğiniz işlemi seçiniz." \
                    --height=200 \
                    --column="İşlem" \
                    "Kullanıcı Ekle" \
                    "Kullanıcı Listele" \
                    "Kullanıcı Güncelle" \
                    "Kullanıcı Sil" )

                case $choice in
                    "")
                        ;;
                    "Kullanıcı Ekle")
                        newUser=$(zenity --forms \
                            --title="Yeni Kullanıcı Ekle" \
                            --text="Gerekli bilgileri giriniz." \
                            --separator="," \
                            --add-entry="Ad" \
                            --add-entry="Soyad" \
                            --add-combo="Yetki" --combo-values="User|Admin" \
                            --add-password="Şifre")
                        
                        # Ok tuşuna basılırsa
                        if [ $? -eq 0 ]; then
                            # Forma girilen girdileri array'e dönüştürüyoruz
                            IFS="," read -ra newUser <<< $newUser

                            # Boş girdi var mı kontrol ediyor
                            if [ "${newUser[0]}" == "" ] || [ "${newUser[1]}" == "" ] || [ "${newUser[2]}" == "" ] || [ "${newUser[3]}" == "" ]; then
                                zenity --error --text="Hiçbir girdi boş bırakılamaz!"
                            else
                                lastUserId=$(tail -n 1 $kullanici | awk -F',' '{printf $1}')
                                if [[ "$lastUserId" =~ ^[0-9]+$ ]]; then
                                    echo "$(($lastUserId+1)),${newUser[0]},${newUser[1]},$([ "${newUser[2]}" == "Admin" ] && echo "1" || echo "0"),$(echo -n ${newUser[3]} | md5sum | awk '{print $1}'),0" >> $kullanici
                                else
                                    echo "0,$(date)," >> $kullanici
                                fi
                                unset lastUserId
                                progress "Kullanıcı oluşturuluyor" "Bilgiler kontrol ediliyr" ".csv dosyası açılıyor" "ID atanıyor" "Kaydediliyor"
                                zenity --info --text="Kullanıcı başarıyla eklenmiştir."
                            fi
                        fi
                        
                        unset newUser
                        ;;
                    "Kullanıcı Listele")
                        zenity --text-info \
                            --title="Kullanıcılar" \
                            --filename=$kullanici \
                            --width=500 --height=300
                        ;;
                    "Kullanıcı Güncelle")
                        ;;
                    "Kullanıcı Sil")
                        ;;
                    *)
                        zenity --error --text="Böyle bir seçenek bulunmamakmtadır!"
                        ;;
                esac
            else
                logging "${user[0]}" "" "'Kullanıcı Yönetimi' işlemine erişilmeye çalışıldı!"
                zenity --error --text="Kullanıcıların 'Kullanıcı Yönetimi' işlemine erişme yetkisi bulunmamaktadır!"
            fi
            ;;
        "Program Yönetimi")
            if [ ${user[3]} -eq 1 ]; then
                choice=$(zenity --list \
                        --title="Program Yönetimi" \
                        --text="Yapmak istediğiniz işlemi seçiniz." \
                        --height=200 \
                        --column="İşlem" \
                        "Diskte Kapladığı Alan" \
                        "Diske Yedek Al" \
                        "Hata Kayıtlarını Göster" )
                
                case $choice in
                    "")
                        ;;
                    "Diskte Kapladığı Alan")
                        ;;
                    "Diske Yedek Al")
                        ;;
                    "Hata Kayıtlarını Göster")
                        ;;
                    *)
                        zenity --error --text="Böyle bir seçenek bulunmamakmtadır!"
                        ;;
                esac
            else
                logging "${user[0]}" "" "'Program Yönetimi' işlemine erişilmeye çalışıldı!"
                zenity --error --text="Kullanıcıların 'Program Yönetimi' işlemine erişme yetkisi bulunmamaktadır!"
            fi
            ;;
        *)
            zenity --error --text="Böyle bir seçenek bulunmamakmtadır!"
            ;;
    esac

done