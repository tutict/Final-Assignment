package com.tutict.finalassignmentcloud.common.realtime;

import com.tutict.finalassignmentcloud.config.redis.SplitRedisConnectionConfiguration;
import org.springframework.boot.autoconfigure.AutoConfiguration;
import org.springframework.boot.autoconfigure.condition.ConditionalOnClass;
import org.springframework.boot.autoconfigure.condition.ConditionalOnMissingBean;
import org.springframework.context.annotation.Bean;
import org.springframework.data.redis.core.StringRedisTemplate;

/**
 * 注册跨服务共享的 WebSocket 票据存储。
 *
 * common 模块的普通组件不在各服务的扫描范围内，因此这里以自动配置的方式下发。
 */
@AutoConfiguration(after = SplitRedisConnectionConfiguration.class)
@ConditionalOnClass(StringRedisTemplate.class)
public class WsTicketStoreAutoConfiguration {

    @Bean
    @ConditionalOnMissingBean
    public WsTicketStore wsTicketStore(StringRedisTemplate stringRedisTemplate) {
        return new WsTicketStore(stringRedisTemplate);
    }
}
