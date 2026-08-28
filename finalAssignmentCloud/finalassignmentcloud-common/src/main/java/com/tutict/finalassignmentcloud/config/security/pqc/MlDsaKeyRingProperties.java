package com.tutict.finalassignmentcloud.config.security.pqc;

import org.springframework.boot.context.properties.ConfigurationProperties;

import java.util.ArrayList;
import java.util.List;

/**
 * ML-DSA 密钥轮换配置。
 *
 * <pre>
 * jwt:
 *   ml-dsa:
 *     rotation:
 *       enabled: false
 *       interval-minutes: 10080
 *       retention-minutes: 1440
 *     keys:
 *       - kid: ml-dsa-2026-01
 *         private-key: |
 *           -----BEGIN PRIVATE KEY-----
 *           ...
 *         public-key: |
 *           -----BEGIN PUBLIC KEY-----
 *           ...
 * </pre>
 *
 * <p>{@code keys} 构成版本化密钥环：签名方以 activeKid（或最后一个含私钥的条目）签名，
 * 校验方保留全部条目做"新旧密钥双验"，直到 retention 窗口结束。
 */
@ConfigurationProperties(prefix = "jwt.ml-dsa")
public class MlDsaKeyRingProperties {

    private List<MlDsaKeyProperties> keys = new ArrayList<>();
    private String activeKid;
    private boolean rotationEnabled = false;
    private long intervalMinutes = 10080;
    private long retentionMinutes = 1440;

    public List<MlDsaKeyProperties> getKeys() {
        return keys;
    }

    public void setKeys(List<MlDsaKeyProperties> keys) {
        this.keys = keys != null ? keys : new ArrayList<>();
    }

    public String getActiveKid() {
        return activeKid;
    }

    public void setActiveKid(String activeKid) {
        this.activeKid = activeKid;
    }

    public boolean isRotationEnabled() {
        return rotationEnabled;
    }

    public void setRotationEnabled(boolean rotationEnabled) {
        this.rotationEnabled = rotationEnabled;
    }

    public long getRetentionMinutes() {
        return retentionMinutes;
    }

    public void setRetentionMinutes(long retentionMinutes) {
        this.retentionMinutes = retentionMinutes;
    }

    public long getIntervalMinutes() {
        return intervalMinutes;
    }

    public void setIntervalMinutes(long intervalMinutes) {
        this.intervalMinutes = intervalMinutes;
    }
}