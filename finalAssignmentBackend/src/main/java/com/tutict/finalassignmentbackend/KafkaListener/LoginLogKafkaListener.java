package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.LoginLog;
import com.tutict.finalassignmentbackend.service.LoginLogService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class LoginLogKafkaListener {

    @Autowired
    public LoginLogKafkaListener(LoginLogService loginLogService) {
    }

    @KafkaListener(topics = "login_log_topic", groupId = "login_log_group")
    public void onLoginLogReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为LoginLog对象
            LoginLog loginLog = deserializeMessage(message);

            // 根据业务需求处理接收到的登录日志，例如进行安全审计或数据分析
            // 这里可以添加自定义的业务逻辑处理代码

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing login log", e);
        }
    }

    private LoginLog deserializeMessage(String message) {
        // 实现JSON字符串到LoginLog对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, LoginLog.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new LoginLog();
    }
}
