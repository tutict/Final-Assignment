package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.rag.entity.RagEmbeddingTask;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface RagEmbeddingTaskMapper extends BaseMapper<RagEmbeddingTask> {
}

