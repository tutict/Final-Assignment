package finalassignmentbackend.service.view;

import finalassignmentbackend.mapper.view.OffenseDetailsMapper;
import finalassignmentbackend.entity.view.OffenseDetails;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import org.eclipse.microprofile.reactive.messaging.Channel;
import org.eclipse.microprofile.reactive.messaging.Emitter;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import java.util.List;

@ApplicationScoped
public class OffenseDetailsService {

    private static final Logger log = LoggerFactory.getLogger(OffenseDetailsService.class);

    @Inject
    OffenseDetailsMapper offenseDetailsMapper;

    @Inject
    @Channel("offense_details_topic")
    Emitter<OffenseDetails> offenseDetailsEmitter;

    public List<OffenseDetails> getAllOffenseDetails() {
        return offenseDetailsMapper.selectList(null);
    }

    public OffenseDetails getOffenseDetailsById(Integer id) {
        return offenseDetailsMapper.selectById(id);
    }

    // 创建方法，用于发送 OffenseDetails 对象到 Kafka 主题
    public void sendOffenseDetailsToKafka(OffenseDetails offenseDetails) {
        offenseDetailsEmitter.send(offenseDetails).toCompletableFuture().exceptionally(ex -> {
            log.error("Failed to send OffenseDetails to Kafka", ex);
            return null;
        });
    }

    public void saveOffenseDetails(OffenseDetails offenseDetails) {
        // 将 offenseDetails 保存到数据库中
        offenseDetailsMapper.insert(offenseDetails);
    }
}
