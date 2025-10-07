define Build/append-bootscript
	cat $@-boot.scr >> $@
endef

define Build/append-kernel-lzma
  $(STAGING_DIR_HOST)/bin/lzma e $(IMAGE_KERNEL) -so >> $@
endef

define Build/tplink-dkmgt-image
  dd if=$(KDIR)/image-$(firstword $(DEVICE_DTS)).dtb bs=$(BLOCKSIZE) conv=sync >> $@.tmp
  $(call Image/pad-to,$@.tmp,$(BLOCKSIZE))
  $(STAGING_DIR_HOST)/bin/lzma e $(IMAGE_KERNEL) -so >> $@.tmp
  $(STAGING_DIR_HOST)/bin/dkmgt-fwutil -c $@ \
    -V "$(VERSION_NUMBER)" -R "$(firstword $(subst -, ,$(REVISION)))" \
    -I "$(VERSION_DIST) $(VERSION_NUMBER) $(REVISION)" \
    -a support-list=$1 -k $@.tmp 
  rm $@.tmp
endef

define Device/FitImage
  KERNEL_SUFFIX := -uImage.itb
  KERNEL = kernel-bin | gzip | fit gzip $$(KDIR)/image-$$(DEVICE_DTS).dtb
  KERNEL_NAME := Image
endef

define Device/UbiFit
  KERNEL_IN_UBI := 1
  IMAGES := factory.ubi sysupgrade.bin
  IMAGE/factory.ubi := append-ubi
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef

define Device/checkpoint_v-80
  $(call Device/Default-arm64)
  DEVICE_VENDOR := Check Point
  DEVICE_MODEL := V-80
  SOC := armada-7040
  BOOT_SCRIPT := v-80
  IMAGES += sysupgrade.gz
  IMAGE/sysupgrade.gz := boot-scr eMMC | append-bootscript | pad-to 2048 | \
	append-kernel | \
	sysupgrade-tar kernel=$$$$@ dtb=$$(KDIR)/image-$$(DEVICE_DTS).dtb | \
	gzip | append-metadata
  ARTIFACTS := initramfs.dtb initramfs.scr
  ARTIFACT/initramfs.dtb := append-dtb
  ARTIFACT/initramfs.scr := boot-scr INIT | append-bootscript
  DEVICE_PACKAGES := kmod-dsa-mv88e6xxx kmod-hwmon-nct7802 kmod-rtc-ds1307
endef
TARGET_DEVICES += checkpoint_v-80

define Device/checkpoint_v-81
  $(call Device/Default-arm64)
  DEVICE_VENDOR := Check Point
  DEVICE_MODEL := V-81
  SOC := armada-8040
  BOOT_SCRIPT := v-80
  IMAGES += sysupgrade.gz
  IMAGE/sysupgrade.gz := boot-scr eMMC | append-bootscript | pad-to 2048 | \
	append-kernel | \
	sysupgrade-tar kernel=$$$$@ dtb=$$(KDIR)/image-$$(DEVICE_DTS).dtb | \
	gzip | append-metadata
  ARTIFACTS := initramfs.dtb initramfs.scr
  ARTIFACT/initramfs.dtb := append-dtb
  ARTIFACT/initramfs.scr := boot-scr INIT | append-bootscript
  DEVICE_PACKAGES := kmod-dsa-mv88e6xxx kmod-hwmon-nct7802 kmod-rtc-ds1307
endef
TARGET_DEVICES += checkpoint_v-81

define Device/globalscale_mochabin
  $(call Device/Default-arm64)
  DEVICE_VENDOR := Globalscale
  DEVICE_MODEL := MOCHAbin
  DEVICE_PACKAGES += kmod-dsa-mv88e6xxx
  SOC := armada-7040
endef
TARGET_DEVICES += globalscale_mochabin

define Device/marvell_armada7040-db
  $(call Device/Default-arm64)
  DEVICE_VENDOR := Marvell
  DEVICE_MODEL := Armada 7040 Development Board
  DEVICE_DTS := armada-7040-db
  IMAGE/sdcard.img.gz := boot-img-ext4 | sdcard-img-ext4 | gzip | append-metadata
endef
TARGET_DEVICES += marvell_armada7040-db

define Device/marvell_armada8040-db
  $(call Device/Default-arm64)
  DEVICE_VENDOR := Marvell
  DEVICE_MODEL := Armada 8040 Development Board
  DEVICE_DTS := armada-8040-db
  IMAGE/sdcard.img.gz := boot-img-ext4 | sdcard-img-ext4 | gzip | append-metadata
endef
TARGET_DEVICES += marvell_armada8040-db

define Device/marvell_macchiatobin-doubleshot
  $(call Device/Default-arm64)
  DEVICE_VENDOR := SolidRun
  DEVICE_MODEL := MACCHIATObin
  DEVICE_VARIANT := Double Shot
  DEVICE_ALT0_VENDOR := SolidRun
  DEVICE_ALT0_MODEL := Armada 8040 Community Board
  DEVICE_ALT0_VARIANT := Double Shot
  DEVICE_PACKAGES += kmod-i2c-mux-pca954x
  DEVICE_DTS := armada-8040-mcbin
  SUPPORTED_DEVICES := marvell,armada8040-mcbin-doubleshot marvell,armada8040-mcbin
endef
TARGET_DEVICES += marvell_macchiatobin-doubleshot

define Device/marvell_macchiatobin-singleshot
  $(call Device/Default-arm64)
  DEVICE_VENDOR := SolidRun
  DEVICE_MODEL := MACCHIATObin
  DEVICE_VARIANT := Single Shot
  DEVICE_ALT0_VENDOR := SolidRun
  DEVICE_ALT0_MODEL := Armada 8040 Community Board
  DEVICE_ALT0_VARIANT := Single Shot
  DEVICE_PACKAGES += kmod-i2c-mux-pca954x
  DEVICE_DTS := armada-8040-mcbin-singleshot
  SUPPORTED_DEVICES := marvell,armada8040-mcbin-singleshot
endef
TARGET_DEVICES += marvell_macchiatobin-singleshot

define Device/mikrotik_rb5009
  $(call Device/Default-arm64)
  $(Device/NAND-128K)
  $(call Device/FitImage)
  $(call Device/UbiFit)
  DEVICE_VENDOR := MikroTik
  DEVICE_MODEL := RB5009
  SOC := armada-7040
  KERNEL_LOADADDR := 0x22000000
  DEVICE_PACKAGES += kmod-i2c-gpio yafut kmod-dsa-mv88e6xxx
endef
TARGET_DEVICES += mikrotik_rb5009

define Device/marvell_clearfog-gt-8k
  $(call Device/Default-arm64)
  DEVICE_VENDOR := SolidRun
  DEVICE_MODEL := Clearfog
  DEVICE_VARIANT := GT-8K
  DEVICE_PACKAGES += kmod-i2c-mux-pca954x kmod-crypto-hw-safexcel
  DEVICE_DTS := armada-8040-clearfog-gt-8k
  SUPPORTED_DEVICES := marvell,armada8040-clearfog-gt-8k
endef
TARGET_DEVICES += marvell_clearfog-gt-8k

define Device/iei_puzzle-m901
  $(call Device/Default-arm64)
  SOC := cn9131
  DEVICE_VENDOR := iEi
  DEVICE_MODEL := Puzzle-M901
  DEVICE_PACKAGES += kmod-rtc-ds1307
endef
TARGET_DEVICES += iei_puzzle-m901

define Device/iei_puzzle-m902
  $(call Device/Default-arm64)
  SOC := cn9132
  DEVICE_VENDOR := iEi
  DEVICE_MODEL := Puzzle-M902
  DEVICE_PACKAGES += kmod-rtc-ds1307
endef
TARGET_DEVICES += iei_puzzle-m902

define Device/solidrun_clearfog-pro
  $(call Device/Default-arm64)
  SOC := cn9130
  DEVICE_VENDOR := SolidRun
  DEVICE_MODEL := ClearFog Pro
  DEVICE_PACKAGES += kmod-i2c-mux-pca954x kmod-dsa-mv88e6xxx
  BOOT_SCRIPT := clearfog-pro
endef
TARGET_DEVICES += solidrun_clearfog-pro

define Device/tplink_er8411
  $(call Device/Default-arm64)
  $(Device/NAND-128K)
  SOC := cn9131
  DEVICE_VENDOR := TP-Link
  DEVICE_MODEL := ER8411
  DEVICE_PACKAGES += kmod-i2c-mux-pca954x kmod-dsa-mv88e6xxx
  DEVICE_DTS := cn9131-tplink-er8411
  KERNEL := append-dtb | pad-to 128k | append-kernel-lzma
  KERNEL_INITRAMFS := tplink-dkmgt-image tplink-er8411-supported-devices.json
  KERNEL_INITRAMFS_SUFFIX := -recovery.bin
endef
TARGET_DEVICES += tplink_er8411
