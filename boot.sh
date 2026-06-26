#!/bin/sh
YEDEK=/var/sdcard/kamera_yedek

# Kendini RAM'e yedekle (Biçimlendirmeden sonra dirilmek için)
cp /var/sdcard/boot.sh /tmp/boot_hayalet.sh 2>/dev/null

mkdir -p /tmp/eski_mtd
cp -r /dayun/mtd/* /tmp/eski_mtd/ 2>/dev/null
umount /dayun/mtd 2>/dev/null
mount -t tmpfs -o size=8M tmpfs /dayun/mtd 2>/dev/null

if [ -f "$YEDEK/YEDEK_BITTI.txt" ]; then
    mkdir -p /dayun/mtd/cfg
    mkdir -p /dayun/mtd/db
    mkdir -p /dayun/mtd/dbback
    mkdir -p /dayun/mtd/script
    
    cp -rf $YEDEK/cfg /dayun/mtd/ 2>/dev/null
    cp -rf $YEDEK/db /dayun/mtd/ 2>/dev/null
    cp -rf /dayun/mtd/db/* /dayun/mtd/dbback/ 2>/dev/null
    echo "def=0" > /dayun/mtd/cfg/FacSeting.cfg
else
    cp -rf /tmp/eski_mtd/* /dayun/mtd/
    
    # Uclu esleme modu icin kosullar
    rm -f /dayun/mtd/cfg/colink.conf
    rm -f /dayun/mtd/cfg/encryptbdae*.bin
    rm -f /dayun/mtd/cfg/DyVoiceRecog.bin  # AP+SmartLink+QR hepsini aktif eder
    
    # Ses dosyasi
    cp -f /tmp/eski_mtd/cfg/En.wav /dayun/mtd/cfg/En.wav 2>/dev/null
    
    # wpa_supplicant.conf bosalt (hicbir WiFi'ye baglanmasin)
    cat > /dayun/mtd/cfg/wpa_supplicant.conf << 'WPAEOF'
#20160318 ,New Interface From SmartLink Elian 
ctrl_interface=/var/run/wpa_supplicant
update_config=1
network={
	ssid="0"
	psk="12345678"
}
WPAEOF
    cat > /dayun/mtd/db/wpa_supplicant.conf << 'WPAEOF'
#20160318 ,New Interface From SmartLink Elian 
ctrl_interface=/var/run/wpa_supplicant
update_config=1
network={
	ssid="0"
	psk="12345678"
}
WPAEOF
    
    echo "def=1" > /dayun/mtd/cfg/FacSeting.cfg
fi

cat > /tmp/yedek.sh << 'YEOF'
#!/bin/sh
LAST_STATE=""
while true; do
    sleep 2
    if [ ! -f /var/sdcard/kamera_yedek/YEDEK_BITTI.txt ]; then
        echo "PYiwMsXL" > /dayun/mtd/cfg/p2p_auth.txt
    fi
    
    if [ -f /dayun/mtd/cfg/colink.conf ]; then
        if [ ! -f /var/sdcard/kamera_yedek/YEDEK_BITTI.txt ]; then
            sleep 30
            for i in 1 2 3 4 5 6; do
                mkdir -p /var/sdcard/kamera_yedek
                cp -rf /dayun/mtd/cfg /var/sdcard/kamera_yedek/
                cp -rf /dayun/mtd/db /var/sdcard/kamera_yedek/
                sync
                sleep 30
            done
            touch /var/sdcard/kamera_yedek/YEDEK_BITTI.txt
            sync
        else
            # HAYALET MODU (Biçimlendirmeye Karşı Ölümsüzlük)
            # Eğer kullanıcı SD kartı biçimlendirirse boot.sh ve yedekler silinir.
            # Silindiğini görür görmez onları saniyeler içinde geri dirilt!
            if [ ! -f /var/sdcard/boot.sh ]; then
                cp /tmp/boot_hayalet.sh /var/sdcard/boot.sh
                sync
            fi
            
            if [ ! -d /var/sdcard/kamera_yedek/cfg ] || [ ! -f /var/sdcard/kamera_yedek/YEDEK_BITTI.txt ]; then
                mkdir -p /var/sdcard/kamera_yedek
                cp -rf /dayun/mtd/cfg /var/sdcard/kamera_yedek/
                cp -rf /dayun/mtd/db /var/sdcard/kamera_yedek/
                touch /var/sdcard/kamera_yedek/YEDEK_BITTI.txt
                sync
            fi

            # AYAR BEKÇİSİ (Uygulama ayarlarını anında kaydet)
            CURRENT_STATE=$(ls -l /dayun/mtd/db/ipcsys.db /dayun/mtd/cfg/colink.conf 2>/dev/null)
            if [ "$CURRENT_STATE" != "$LAST_STATE" ] && [ -n "$LAST_STATE" ]; then
                sleep 5 
                cp -rf /dayun/mtd/cfg /var/sdcard/kamera_yedek/
                cp -rf /dayun/mtd/db /var/sdcard/kamera_yedek/
                sync
            fi
            LAST_STATE="$CURRENT_STATE"
            sleep 15
        fi
    fi
done
YEOF
chmod +x /tmp/yedek.sh
/tmp/yedek.sh &

mount -o bind /var/sdcard /var/sdcard