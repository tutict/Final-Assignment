package com.tutict.finalassignmentbackend.KafkaListener;

import com.tutict.finalassignmentbackend.entity.SystemLogs;
import com.tutict.finalassignmentbackend.service.SystemLogsService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.kafka.support.Acknowledgment;
import org.springframework.stereotype.Service;

@Service
public class SystemLogsKafkaListener {

    @Autowired
    public SystemLogsKafkaListener(SystemLogsService systemLogsService) {
    }

    @KafkaListener(topics = "system_logs_topic", groupId = "system_logs_group")
    public void onSystemLogsReceived(String message, Acknowledgment acknowledgment) {
        try {
            // 反序列化消息内容为SystemLogs对象
            SystemLogs systemLog = deserializeMessage(message);

            // 根据业务需求处理接收到的系统日志，例如进行安全审计或数据分析
            // 这里可以添加自定义的业务逻辑处理代码

            // 确认消息处理成功
            acknowledgment.acknowledge();
        } catch (Exception e) {
            // 处理异常，可以选择不确认消息，以便Kafka重新投递
            // acknowledgment.nack(false, false);
            // log.error("Error processing system log", e);
        }
    }

    private SystemLogs deserializeMessage(String message) {
        // 实现JSON字符串到SystemLogs对象的反序列化
        // 这里需要一个合适的JSON转换器，例如Jackson的ObjectMapper
        // ObjectMapper objectMapper = new ObjectMapper();
        // return objectMapper.readValue(message, SystemLogs.class);

        // 模拟反序列化过程，实际应用中需要替换为上述代码
        return new SystemLogs();
    }
}