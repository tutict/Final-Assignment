package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.rag.entity.RagChunk;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface RagChunkMapper extends BaseMapper<RagChunk> {
}

