package com.tutict.finalassignmentcloud.config.security.crypto;

import com.tutict.finalassignmentcloud.entity.AppealRecord;
import com.tutict.finalassignmentcloud.entity.DriverInformation;
import com.tutict.finalassignmentcloud.entity.PaymentRecord;
import com.tutict.finalassignmentcloud.entity.VehicleInformation;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.function.Consumer;

@Service
public class SensitiveDataPersistenceService {

    private final SensitiveDataCryptoService cryptoService;

    public SensitiveDataPersistenceService(SensitiveDataCryptoService cryptoService) {
        this.cryptoService = cryptoService;
    }

    public void prepare(DriverInformation driver) {
        if (driver == null) {
            return;
        }
        populate(driver.getIdCardNumber(), driver::setIdCardNumberCiphertext, driver::setIdCardNumberBlindIndex);
        populate(driver.getContactNumber(), driver::setContactNumberCiphertext, driver::setContactNumberBlindIndex);
    }

    public void prepare(VehicleInformation vehicle) {
        if (vehicle == null) {
            return;
        }
        populate(vehicle.getOwnerIdCard(), vehicle::setOwnerIdCardCiphertext, vehicle::setOwnerIdCardBlindIndex);
        populate(vehicle.getOwnerContact(), vehicle::setOwnerContactCiphertext, vehicle::setOwnerContactBlindIndex);
    }

    public void prepare(PaymentRecord payment) {
        if (payment == null) {
            return;
        }
        populate(payment.getPayerIdCard(), payment::setPayerIdCardCiphertext, payment::setPayerIdCardBlindIndex);
        populate(payment.getPayerContact(), payment::setPayerContactCiphertext, payment::setPayerContactBlindIndex);
        populate(payment.getBankAccount(), payment::setBankAccountCiphertext, payment::setBankAccountBlindIndex);
    }

    public void prepare(AppealRecord appeal) {
        if (appeal == null) {
            return;
        }
        populate(appeal.getAppellantIdCard(), appeal::setAppellantIdCardCiphertext, appeal::setAppellantIdCardBlindIndex);
        populate(appeal.getAppellantContact(), appeal::setAppellantContactCiphertext, appeal::setAppellantContactBlindIndex);
    }

    public String blindIndex(String value) {
        return cryptoService.blindIndex(value);
    }

    public String ciphertext(String value) {
        if (!StringUtils.hasText(value) || !cryptoService.isEnabled()) {
            return null;
        }
        return cryptoService.encrypt(value.trim());
    }

    private void populate(String value, Consumer<String> ciphertextSetter, Consumer<String> blindIndexSetter) {
        if (!StringUtils.hasText(value)) {
            ciphertextSetter.accept(null);
            blindIndexSetter.accept(null);
            return;
        }
        String trimmed = value.trim();
        ciphertextSetter.accept(ciphertext(trimmed));
        blindIndexSetter.accept(blindIndex(trimmed));
    }
}
