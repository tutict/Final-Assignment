package finalassignmentbackend.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import finalassignmentbackend.rag.entity.RagDocument;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface RagDocumentMapper extends BaseMapper<RagDocument> {
}

