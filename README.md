# linux-zenity-odev
### [Videonun Linki](https://youtu.be/RCDL3Twc0Qc)
### [GitHub Linki](https://github.com/erengureli/linux-zenity-odev)

Bu proje zenity kütüphanesi kullanılarak linux bash içinde yazılmış envanter sistemidir. Projenin amacı linux bash ve zenity'yi daha detaylı öğrenebilmektir. Şimdi bütün menüleri teker teker gösterip açıklayacağım.

# 1. Giriş Ekranı
![Admin Ana Menü](media/login.png)

Giriş yapmak için ID ve şifrenin istendiği arayüz. Eğer hatalı şifre girilirse uyarı verip logladıktan sonra `passtry` değişkenini 1 arttırmaktadır. Eğer bu değer 3 olursa hesap kitlenir ve bir yönetici olmadan açılamaz.

# 2. Ana Menü
![Admin Ana Menü](media/adminMenu.png)
![Kullanıcı Ana Menü](media/userMenu.png)

Kullanıcı ve Yönetici için ayrı ana menü tasarlanmıştır. Bu tasarımdan dolayı kullanıcılar yönetici yetkili sayfalara girememektedir. Eğer kullanıcılar bir şekilde admin paneline erişirse ve bir işlem gerçekleştirirse karşılarına hata mesajı çıkmaktadır.

## 2.1. Ürün Ekle
![Ürün Ekle Menü](media/productAdd.png)

Eklemek istenilen ürünün bilgileri kontrol edildikten sonra OK'a basılınca direkt kullanici.csv dosyasının içine kaydediyor.

## 2.2. Ürün Listele
![Ürün Listele Menü](media/productList.png)

`depo.csv` dosyasını yazdırmaktadır.

## 2.3. Ürün Güncelle
![Ürün Güncelle ID Menü](media/productUpd1.png)
![Ürün Güncelle Bilgiler Menü](media/productUpd2.png)

Girilen ID'deki ürünün bilgilerini, girilen bilgilerden boş olmayanları kontrol ederek `depo.csv` dosyasını değiştirir.

## 2.4. Ürün Sil
![Ürün Sil ID Menü](media/productDel.png)

Girilen ID'deki ürün varsa ürün bilgilerini boş yapıyor bu sayede silinmiş oluyor. ID silinmediğinden ve başka ürüne geçmediğinden loglardan takip edilebiliyor.

## 2.5. Rapor Al
![Rapor Al Menü](media/getReport.png)

### 2.5.1. En Fazla Stoğu Olan Ürünler
![En Fazla Stoğu Olan Ürünler Menü](media/mostStock.png)

### 2.5.2. Girilen Değerden Az Stoğu Olan Ürünler
![Girilen Değerden Az Stoğu Olan Ürünler Stok Menü](media/leastStock1.png)
![Girilen Değerden Az Stoğu Olan Ürünler Menü](media/leastStock2.png)

### 2.5.3. Girilen Kategoride Bulunan Ürünler
![Girilen Kategoride Bulunan Ürünler Kategori Menü](media/categoryFind1.png)
![Girilen Kategoride Bulunan Ürünler Menü](media/categoryFind2.png)

### 2.5.4. Ürünlerin Toplam Değeri
![Ürünlerin Toplam Değeri Menü](media/totalPrice.png)

## 2.6. Kullanıcı Yönetimi
![Kullanıcı Yönetimi Menü](media/userManagement.png)

### 2.6.1. Kullanıcı Ekle
![Kullanıcı Ekle Menü](media/userAdd.png)

Girilen şifreyi md5 ile şifreleyip en son kullanıcının ID'sinden 1 fazla ID atayıp yeni kullanıcı oluşturur. Hiç kullanıcı yoksa 0 atar.

### 2.6.2. Kullanıcı Listele
![Kullanıcı Listele Menü](media/userList.png)

`kullanici.csv` dosyasını yazdırmaktadır.

### 2.6.3 Kullanıcı Güncelle
![Kullanıcı Güncelle ID Menü](media/userUpd1.png)
![Kullanıcı Güncelle Menü](media/userUpd2.png)

Girilen ID'deki kullanıcı bilgilerini, girilen bilgilerden boş olmayanları kontrol ederek `kullanici.csv` dosyasını değiştirir.

### 2.6.4. Kullanıcı Sil
![Kullanıcı Sil Menü](media/userDel.png)

Girilen ID'deki kullanıcı varsa kullanıcının bilgilerini boş yapıyor bu sayede silinmiş oluyor. ID silinmediğinden ve başka kullanıcıya geçmediğinden loglardan takip edilebiliyor.

## 2.7. Program Yönetimi
![Program Yönetimi Menü](media/programManagement.png)

## 2.7.1. Diskte Kapladığı Alan
![Diskte Kapladığı Alan Menü](media/diskSpace.png)

## 2.7.2. Diske Yedek Al

Çıkan menüden bir klasör seçilir. Seçilen klasöre bütün .csv dosyaları kopyalanmaktadır.

## 2.7.3. Hata Kayıtlarını Göster
![Hata Kayıtlarını Göster Menü](media/logList.png)

## 2.8. Çıkış Yap

`Çıkış Yap`, `Cancel` ya da sağ üstteki X tuşuna basınca programdan çıkmaktadır.
