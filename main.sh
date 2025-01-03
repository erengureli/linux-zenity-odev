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
    echo "id,name,amount,price,category" > $depo
fi
if [ ! -f $kullanici ]; then
    touch $kullanici
    echo "id,name,surname,role,password,passtry" > $kullanici
    echo "0,Eren,GÜRELİ,1,81dc9bdb52d04dc20036dbd8313ed055,0" >> $kullanici
fi
if [ ! -f $log ]; then
    touch $log
    echo "id,date,userId,product,log" > $log
    echo "0,$(date),-1,,log.csv dosyası oluşturuldu." >> $log
fi

# Hızlı loglamak için fonksiyon -> userId product log
logging(){
    lastLogId=$(tail -n 1 $log | awk -F',' '{printf $1}')

    if [[ ! "$lastLogId" =~ ^[+-]?[0-9]+$ ]]; then
        lastLogId=-1
    fi

    echo "$(($lastLogId+1)),$(date),$1,$2,$3" >> $log

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

# Bütün kullanıcıları kontrol ediyoruz
HEADER_SKIPPED=false
USER_FIND=false
while IFS="," read -ra user; do
    # İlk elemanı atlıyoruz
    if [ $HEADER_SKIPPED = false ]; then
        HEADER_SKIPPED=true
        continue
    fi

    # id'yi kontrol ediyoruz
    if [ "${loginData[0]}" == "${user[0]}" ]; then
        USER_FIND=true
        # şifre deneme sayısını kontrol ediyoruz
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
done < $kullanici

# Kullanıcı bulunamadıysa hata verip programı kapatıyoruz
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
        echo "20" ; sleep 0.3
        echo "# $3" ; sleep 0.3
        echo "40" ; sleep 0.3
        echo "60" ; sleep 0.3
        echo "# $4" ; sleep 0.3
        echo "80" ; sleep 0.3
        echo "# $5" ; sleep 0.3
        echo "100" ; sleep 0.3
    ) |
    zenity --progress \
        --title="$1" \
        --text="$2" \
        --percentage=0
}

# ============== Products ==============

productAdd(){
    newProduct=$(zenity --forms \
        --title="Yeni Ürün Ekle" \
        --text="Gerekli bilgileri giriniz." \
        --separator="," \
        --add-entry="Ürün İsmi" \
        --add-entry="Ürün Miktarı" \
        --add-entry="Birim Fiyatı" \
        --add-entry="Kategorisi" )

    # Ok tuşuna basılırsa
    if [ $? -eq 0 ]; then
        # Forma girilen girdileri array'e dönüştürüyoruz
        IFS="," read -ra newProduct <<< $newProduct

        # Gerekli kontrolleri yapıp uyarı mesajı veriyoruz
        if [ "${newProduct[0]}" == "" ] || [ "${newProduct[1]}" == "" ] || [ "${newProduct[2]}" == "" ] || [ "${newProduct[3]}" == "" ]; then
            zenity --error --text="Hiçbir girdi boş bırakılamaz!"
        elif [[ ! ${newProduct[1]} =~ ^[+-]?[0-9]+$ ]]; then
            zenity --error --text="Ürün miktarı tam sayı olmalıdır."
        elif [ ${newProduct[1]} -lt 0 ]; then
            zenity --error --text="Ürün miktarı negatif olamaz."
        elif [[ ! ${newProduct[2]} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
            zenity --error --text="Ürün fiyatı sayı olmalıdır."
        elif [ $( echo ${newProduct[2]} | awk -F'.' '{print $1}' ) -le 0 ]; then
            zenity --error --text="Ürün fiyatı sıfır ya da negatif olamaz."
        else

            # Aynı isimde ürün var mı diye kontrol ediyoruz
            HEADER_SKIPPED=false
            PRODUCT_FIND=false
            while IFS="," read -ra product; do
                # İlk elemanı atlıyoruz
                if [ $HEADER_SKIPPED = false ]; then
                    HEADER_SKIPPED=true
                    continue
                fi

                # Aynı isimde ürün varsa döngüden çıkıyor
                if [ "${product[1]}" == "${newProduct[0]}" ]; then
                    PRODUCT_FIND=true
                    break
                fi
            done < $depo

            # Aynı isimde ürün varsa uyarı mesajı yazdırıyor
            if [ $PRODUCT_FIND = true ]; then
                zenity --error --text="Aynı isimde birden fazla ürün bulunamaz."
            else
                lastProductId=$(tail -n 1 $depo | awk -F',' '{printf $1}')
                if [[ ! "$lastProductId" =~ ^[+-]?[0-9]+$ ]]; then
                    lastProductId=-1 
                fi

                echo "$(($lastProductId+1)),${newProduct[0]},${newProduct[1]},${newProduct[2]},${newProduct[3]}" >> $depo
                
                logging "${user[0]}" "$(($lastProductId+1))" "Yeni bir ürün eklenmiştir."
                progress "Ürün Oluşturuluyor" "Bilgiler kontrol ediliyor" ".csv dosyası açılıyor" "ID atanıyor" "Kaydediliyor"
                zenity --info --text="Ürün başarıyla eklenmiştir."
                
                unset lastProductId
            fi

            unset HEADER_SKIPPED
            unset PRODUCT_FIND
            unset product        
        fi
    fi

    unset newProduct
}

productList(){
    zenity --text-info \
        --title="Ürünler" \
        --filename=$depo \
        --width=500 --height=300
}

productUpd(){
    productUpdId=$(zenity --forms \
        --title="Kullanıcı Güncelle" \
        --text="Güncellemek istediğiniz kullanıcının ID'sini giriniz" \
        --add-entry="ID" )
    index=$(($productUpdId+2))

    # Ok tuşuna basıldı mı kontrol
    if [ $? -eq 0 ] && [ ! $productUpdId == "" ]; then
        # Sayı mı kontrol
        if [[ $productUpdId =~ ^[0-9]+$ ]]; then
            # Bu ID de kullanıcı var mı
            if [ ! $(wc -l < $depo) -lt $index ] && [ ! $(sed -n $index"p" $depo) == $productUpdId",,,," ]; then
                IFS="," read -ra productData <<< $(sed -n $index"p" $depo)
                
                newProduct=$(zenity --forms \
                    --title="Yeni Ürün Ekle" \
                    --text="Gerekli bilgileri giriniz." \
                    --separator="," \
                    --add-entry="Ürün İsmi" \
                    --add-entry="Ürün Miktarı" \
                    --add-entry="Birim Fiyatı" \
                    --add-entry="Kategorisi" )

                # Ok tuşuna basılırsa
                if [ $? -eq 0 ]; then
                    # Forma girilen girdileri array'e dönüştürüyoruz
                    IFS="," read -ra newProduct <<< $newProduct

                    # Gerekli kontrolleri yapıp uyarı mesajı veriyoruz
                    if [ ! ${newProduct[1]} == "" ] && [[ ! ${newProduct[1]} =~ ^[+-]?[0-9]+$ ]]; then
                        zenity --error --text="Ürün miktarı tam sayı olmalıdır."
                    elif [ ! ${newProduct[1]} == "" ] && [ ${newProduct[1]} -lt 0 ]; then
                        zenity --error --text="Ürün miktarı negatif olamaz."
                    elif [ ! ${newProduct[2]} == "" ] && [[ ! ${newProduct[2]} =~ ^[+-]?[0-9]+\.?[0-9]*$ ]];then
                        zenity --error --text="Ürün fiyatı sayı olmalıdır."
                    elif [ ! ${newProduct[2]} == "" ] && [ ! ${newProduct[2]} == "" ] && [ $( echo ${newProduct[2]} | awk -F'.' '{print $1}' ) -le 0 ]; then
                        zenity --error --text="Ürün fiyatı sıfır ya da negatif olamaz."
                    else
                        # Aynı isimde ürün var mı diye kontrol ediyoruz
                        HEADER_SKIPPED=false
                        PRODUCT_FIND=false
                        while IFS="," read -ra product; do
                            # İlk elemanı atlıyoruz
                            if [ $HEADER_SKIPPED = false ]; then
                                HEADER_SKIPPED=true
                                continue
                            fi

                            # Aynı isimde ürün varsa döngüden çıkıyor
                            if [ "${productData[1]}" == "${newProduct[0]}" ]; then
                                PRODUCT_FIND=true
                                break
                            fi
                        done < $depo

                        # Aynı isimde ürün varsa uyarı mesajı yazdırıyor
                        if [ $PRODUCT_FIND = true ]; then
                            zenity --error --text="Aynı isimde birden fazla ürün bulunamaz."
                        else
                            # Güncelleme işlemi için onay alıyoruz
                            zenity --question --text="Eski veriler kalıcı olarak silinecektir. Kaydetmek istediğinize emin misiniz?"
                            if [ $? -eq 0 ]; then
                                updProduct=${productData[0]}","$( [ "${newProduct[0]}" == "" ] && echo ${productData[1]} || echo ${newProduct[0]} )","$( [ "${newProduct[1]}" == "" ] && echo ${productData[2]} || echo ${newProduct[1]} )","$( [ "${newProduct[2]}" == "" ] && echo ${productData[3]} || echo ${newProduct[2]} )","$( [ "${newProduct[3]}" == "" ] && echo ${productData[4]} || echo ${newProduct[3]} )

                                sed -i $index"s/.*/$updProduct/" $depo

                                logging "${user[0]}" "${productData[0]}" "Ürün güncellenmiştir."
                                progress "Ürün Güncelleniyor" "Bilgiler kontrol ediliyor" ".csv dosyası açılıyor" "Bilgiler değiştiriliyor" "Kaydediliyor"
                                zenity --info --text="Ürün başarıyla güncellenmiştir."

                                unset updProduct
                            fi
                        fi

                        unset HEADER_SKIPPED
                        unset PRODUCT_FIND
                        unset product
                    fi
                fi

                unset productData
                unset newProduct
            else
                zenity --error --text="Bu ID'ye sahip bir ürün bulunmamaktadır!"
            fi
        else
            zenity --error --text="ID 0'dan büyük tam sayı olmalıdır!"
        fi
    fi

    unset productUpdId
    unset index
}

productDel(){
    productDelId=$(zenity --forms \
        --title="Ürün Sil" \
        --text="Silmek istediğiniz ürünün ID'sini giriniz" \
        --add-entry="ID" )
    index=$(($productDelId+2))
    
    if [ $? -eq 0 ] && [ ! $productDelId == "" ] && [ ! $(wc -l < $depo) -lt $index ]; then 
        # Silme işlemi için onay alıyoruz
        zenity --question --text="Eski veriler kalıcı olarak silinecektir. Silmek istediğinize emin misiniz?"
        if [ $? -eq 0 ]; then
            sed -i $index"s/.*/$productDelId,,,,/" $depo

            logging "${user[0]}" "$productDelId" "Ürün silinmiştir."
            progress "Ürün Siliniyor" "Bilgiler kontrol ediliyor" ".csv dosyası açılıyor" "Bilgiler siliniyor" "Kaydediliyor"
            zenity --info --text="Ürün başarıyla silinmiştir."
        fi
    else
        zenity --error --text="Bu ID'ye sahip bir ürün bulunmamaktadır!"
    fi

    unset productDelId
    unset index
}

# ============== Reports ==============

mostStock(){
    mostStockAmount=0

    # Bütün ürünleri arıyor
    HEADER_SKIPPED=false
    while IFS="," read -ra product; do
        # İlk elemanı atlıyoruz
        if [ $HEADER_SKIPPED = false ]; then
            HEADER_SKIPPED=true
            continue
        fi

        # Elimizdekinden daha fazla sayıda ürünü bulunan bir ürüne denk gelirsek onu seçiyoruz
        if [ ! "${product[2]}" == "" ] && [ $mostStockAmount -lt ${product[2]} ]; then
            mostStockAmount=${product[2]}
            mostStockProduct=$(echo "ID:\t\t\t\t"${product[0]}"\nÜrün Adı:\t\t"${product[1]}"\nÜrün Miktarı:\t"${product[2]}"\nBirim Fiyatı:\t"${product[3]}"\nKategori:\t\t"${product[4]})
        fi
    done < $depo

    zenity --info \
        --title="En Fazla Stok" \
        --text="$mostStockProduct"

    unset mostStockAmount
    unset mostStockProduct
    unset HEADER_SKIPPED
}

leastStock(){
    lStock=$(zenity --forms \
        --title="Girilen Stokdan Az" \
        --text="Bir stok değeri girin" \
        --add-entry="Stok" )
    
    # Değer girildi mi
    if [ $? -eq 0 ] && [ ! $lStock == "" ]; then
        # Girilen değer sayı mı
        if [[ "$lStock" =~ ^[+]?[0-9]+$ ]]; then
            infoText=""

            # Bütün ürünleri arıyor
            HEADER_SKIPPED=false
            while IFS="," read -ra product; do
                # İlk elemanı atlıyoruz
                if [ $HEADER_SKIPPED = false ]; then
                    HEADER_SKIPPED=true
                    continue
                fi

                # Elimizdekinden daha fazla sayıda ürünü bulunan bir ürüne denk gelirsek onu seçiyoruz
                if [ ! "${product[2]}" == "" ] && [ $lStock -gt ${product[2]} ]; then
                    infoText=$infoText""$(echo "ID: "${product[0]}"\tÜrün Adı: "${product[1]}"\tÜrün Miktarı: "${product[2]}"\tBirim Fiyatı: "${product[3]}"\tKategori: "${product[4]}"\n")
                fi
            done < $depo

            zenity --info \
                --title="$lStock'dan Az Stok" \
                --text="$infoText" \
                --width=500
        else
            zenity --error --text="Stok değeri 0'dan büyük bir tam sayı olmalıdır!"
        fi
    fi

    unset lStock
    unset infoText
    unset HEADER_SKIPPED
    unset product
}

categoryList(){
    category=$(zenity --forms \
        --title="Girilen Kategorideki Ürünler" \
        --text="Bir kategori girin" \
        --add-entry="Kategori" )
    
    # Değer girildi mi
    if [ $? -eq 0 ] && [ ! $category == "" ]; then
        infoText=""

        # Bütün ürünleri arıyor
        HEADER_SKIPPED=false
        while IFS="," read -ra product; do
            # İlk elemanı atlıyoruz
            if [ $HEADER_SKIPPED = false ]; then
                HEADER_SKIPPED=true
                continue
            fi

            # Elimizdekinden daha fazla sayıda ürünü bulunan bir ürüne denk gelirsek onu seçiyoruz
            if [ ! "${product[4]}" == "" ] && [ $category == ${product[4]} ]; then
                infoText=$infoText""$(echo "ID: "${product[0]}"\tÜrün Adı: "${product[1]}"\tÜrün Miktarı: "${product[2]}"\tBirim Fiyatı: "${product[3]}"\tKategori: "${product[4]}"\n")
            fi
        done < $depo

        zenity --info \
            --title="$lStock'dan Az Stok" \
            --text="$infoText" \
            --width=500
    fi

    unset category
    unset infoText
    unset HEADER_SKIPPED
    unset product
}

totalPrice(){
    totalPrice=0

    # Bütün ürünleri arıyor
    HEADER_SKIPPED=false
    while IFS="," read -ra product; do
        # İlk elemanı atlıyoruz
        if [ $HEADER_SKIPPED = false ]; then
            HEADER_SKIPPED=true
            continue
        fi

        # Elimizdekinden daha fazla sayıda ürünü bulunan bir ürüne denk gelirsek onu seçiyoruz
        if [ ! "${product[3]}" == "" ] && [[ "${product[3]}" =~ ^[+-]?[0-9]+\.?[0-9]*$ ]]; then
            totalPrice=$(bc -l <<< "$totalPrice+$(bc -l <<< "${product[2]}*${product[3]}")")
        fi
    done < $depo

    zenity --info \
        --title="Toplam Fiyat" \
        --text="Toplam Fiyat: $totalPrice"
    
    unset totalPrice
    unset HEADER_SKIPPED
    unset product
}

# ============== Users ==============

userAdd(){
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
            if [[ ! "$lastUserId" =~ ^[0-9]+$ ]]; then
                lastUserId=-1
            fi

            echo "$(($lastUserId+1)),${newUser[0]},${newUser[1]},$([ "${newUser[2]}" == "Admin" ] && echo "1" || echo "0"),$(echo -n ${newUser[3]} | md5sum | awk '{print $1}'),0" >> $kullanici

            logging "${user[0]}" "" "Yeni kullanıcı eklenmiştir."
            progress "Kullanıcı Oluşturuluyor" "Bilgiler kontrol ediliyor" ".csv dosyası açılıyor" "ID atanıyor" "Kaydediliyor"
            zenity --info --text="Kullanıcı başarıyla eklenmiştir."

            unset lastUserId
        fi
    fi

    unset newUser
}

userList(){
    zenity --text-info \
        --title="Kullanıcılar" \
        --filename=$kullanici \
        --width=500 --height=300
}

userUpd(){
    userUpdId=$(zenity --forms \
        --title="Kullanıcı Güncelle" \
        --text="Güncellemek istediğiniz kullanıcının ID'sini giriniz" \
        --add-entry="ID" )
    index=$(($userUpdId+2))

    # Ok a basıldıysa ve girdi boş değilse
    if [ $? -eq 0 ] && [ ! $userUpdId == "" ]; then
        if [[ $userUpdId =~ ^[0-9]+$ ]]; then
            # Bu ID de kullanıcı var mı
            if [ ! $(wc -l < $kullanici) -lt $index ] && [ ! $(sed -n $index"p" $depo) == $userUpdId",,,,," ]; then
                IFS="," read -ra userData <<< $(sed -n $index"p" $kullanici)
                
                newUser=$(zenity --forms \
                    --title="Kullanıcı Güncelle" \
                    --text="Gerekli bilgileri giriniz." \
                    --separator="," \
                    --add-entry="Ad" \
                    --add-entry="Soyad" \
                    --add-combo="Yetki" --combo-values="User|Admin" \
                    --add-password="Şifre" \
                    --add-entry="Şifre Denenme Sayısı")

                # Ok tuşuna basılırsa
                if [ $? -eq 0 ]; then
                    # Güncelleme işlemi için onay alıyoruz
                    zenity --question --text="Eski veriler kalıcı olarak silinecektir. Kaydetmek istediğinize emin misiniz?"
                    if [ $? -eq 0 ]; then
                        # Forma girilen girdileri array'e dönüştürüyoruz
                        IFS="," read -ra newUser <<< $newUser

                        updUser=${userData[0]}","$( [ "${newUser[0]}" == "" ] && echo ${userData[1]} || echo ${newUser[0]} )","$( [ "${newUser[1]}" == "" ] && echo ${userData[2]} || echo ${newUser[1]} )","$( [ "${newUser[2]}" == "" ] && echo ${userData[3]} || echo $([ "${newUser[2]}" == "Admin" ] && echo "1" || echo "0"))","$( [ "${newUser[3]}" == "" ] && echo ${userData[4]} || echo $(echo -n ${newUser[3]} | md5sum | awk '{print $1}') )","$( [ "${newUser[4]}" == "" ] && echo ${userData[5]} || echo ${newUser[4]} )
                        
                        sed -i $index"s/.*/$updUser/" $kullanici

                        logging "${user[0]}" "" "Kullanıcı güncellenmiştir."
                        progress "Kullanıcı Güncelleniyor" "Bilgiler kontrol ediliyor" ".csv dosyası açılıyor" "Bilgiler değiştiriliyor" "Kaydediliyor"
                        zenity --info --text="Kullanıcı başarıyla güncellenmiştir."

                        unset updUser
                    fi
                fi

                unset userData
                unset newUser
                
            else
                zenity --error --text="Bu ID'ye sahip bir kullanıcı bulunmamaktadır!"
            fi
        else
            zenity --error --text="ID 0'dan büyük tam sayı olmalıdır!"
        fi
    fi
    
    unset userUpdId
    unset index

}

userDel(){
    userDelId=$(zenity --forms \
        --title="Kullanıcı Sil" \
        --text="Silmek istediğiniz kullanıcının ID'sini giriniz" \
        --add-entry="ID" )
    index=$(($userDelId+2))
    
    if [ ! $(wc -l < $kullanici) -lt $index ] && [ $? -eq 0 ]; then 
        # Silme işlemi için onay alıyoruz
        zenity --question --text="Eski veriler kalıcı olarak silinecektir. Silmek istediğinize emin misiniz?"
        if [ $? -eq 0 ]; then 
            sed -i $index"s/.*/$userDelId,,,,,/" $kullanici

            logging "${user[0]}" "" "Kullanıcı silinmiştir."
            progress "Kullanıcı Siliniyor" "Bilgiler kontrol ediliyor" ".csv dosyası açılıyor" "Bilgiler siliniyor" "Kaydediliyor"
            zenity --info --text="Kullanıcı başarıyla silinmiştir."
        fi
    else
        zenity --error --text="Bu ID'ye sahip bir kullanıcı bulunmamaktadır!"
    fi

    unset userDelId
    unset index

}

# ============== Programs ==============

diskSpace(){
    zenity --info \
        --title="Disk Alanı" \
        --text="depo.csv:\t\t$(du -h $depo | cut -f1)\nkullanici.csv:\t$(du -h $kullanici | cut -f1)\nlog.csv:\t\t$(du -h $log | cut -f1)\nmain.sh:\t\t$(du -h "main.sh" | cut -f1)\nTotal:\t\t\t$(du -h $depo $kullanici $log "main.sh" | awk '{total += $1} END {print total}')K"
}

backup(){
    backupLoc=$(zenity --file-selection \
        --title="Boş bir klasör seçini" \
        --directory)
    if [ $? -eq 0 ] && [ ! $backupLoc == "" ]; then
        cp $folder/* $backupLoc
        
        logging "${user[0]}" "" "Backup dosyası oluşturulmuştur."
        progress "Backup Dosyası oluşturuluyor" "Bilgiler kontrol ediliyor" ".csv dosyasyaları kopyalanıyor" "Kaydediliyor" "Kaydediliyor"
        zenity --info --text="Backup dosyası başarıyla oluşturulmuştur."
    fi
}

logList(){
    zenity --text-info \
        --title="Kayıtlar" \
        --filename=$log \
        --width=500 --height=300
}


# Sonsuz döngü içinde işlem yapıyoruz
while true; do
    # Admin ise farklı, user ise farklı arayüz çıkacak
    if [ ${user[3]} -eq 1 ]; then
        choice=$(zenity --list \
            --title="Admin Ana Menü" \
            --text="Yapmak istediğiniz işlemi seçiniz." \
            --height=300 \
            --column="İşlem" \
            "Ürün Ekle" \
            "Ürün Listele" \
            "Ürün Güncelle" \
            "Ürün Sil" \
            "Rapor Al" \
            "Kullanıcı Yönetimi" \
            "Program Yönetimi" \
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
            if [ ${user[3]} -eq 1 ]; then
                productAdd
            else
                logging "${user[0]}" "" "'Ürün Ekle' işlemine erişilmeye çalışıldı!"
                zenity --error --text="Kullanıcıların 'Ürün Ekle' işlemine erişme yetkisi bulunmamaktadır!"
            fi
            ;;
        "Ürün Listele")
            productList
            ;;
        "Ürün Güncelle")
            if [ ${user[3]} -eq 1 ]; then
                productUpd
            else
                logging "${user[0]}" "" "'Ürün Güncelle' işlemine erişilmeye çalışıldı!"
                zenity --error --text="Kullanıcıların 'Ürün Güncelle' işlemine erişme yetkisi bulunmamaktadır!"
            fi
            ;;
        "Ürün Sil")
            if [ ${user[3]} -eq 1 ]; then
                productDel
            else
                logging "${user[0]}" "" "'Ürün Sil' işlemine erişilmeye çalışıldı!"
                zenity --error --text="Kullanıcıların 'Ürün Sil' işlemine erişme yetkisi bulunmamaktadır!"
            fi
            ;;
        "Rapor Al")
            choice=$(zenity --list \
                    --title="Rapor Al" \
                    --text="Yapmak istediğiniz işlemi seçiniz." \
                    --height=200 \
                    --width=300 \
                    --column="İşlem" \
                    "En Fazla Stoğu Olan Ürünler" \
                    "Girlen Değerden Az Stoğu Olan Ürünler" \
                    "Girilen Kategoride Bulunan Ürünler" \
                    "Ürünlerin Toplam Değeri" )
            
            case $choice in
                "")
                    ;;
                "En Fazla Stoğu Olan Ürünler")
                    mostStock
                    ;;
                "Girlen Değerden Az Stoğu Olan Ürünler")
                    leastStock
                    ;;
                "Girilen Kategoride Bulunan Ürünler")
                    categoryList
                    ;;
                "Ürünlerin Toplam Değeri")
                    totalPrice
                    ;;
                *)
                    zenity --error --text="Böyle bir seçenek bulunmamakmtadır!"
                    ;;
            esac
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
                        userAdd
                        ;;
                    "Kullanıcı Listele")
                        userList
                        ;;
                    "Kullanıcı Güncelle")
                        userUpd
                        ;;
                    "Kullanıcı Sil")
                        userDel
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
                    --height=180 \
                    --column="İşlem" \
                    "Diskte Kapladığı Alan" \
                    "Diske Yedek Al" \
                    "Hata Kayıtlarını Göster" )

                case $choice in
                    "")
                        ;;
                    "Diskte Kapladığı Alan")
                        diskSpace
                        ;;
                    "Diske Yedek Al")
                        backup
                        ;;
                    "Hata Kayıtlarını Göster")
                        logList
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