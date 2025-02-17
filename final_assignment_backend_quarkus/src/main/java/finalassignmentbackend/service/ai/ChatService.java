package finalassignmentbackend.service.ai;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import io.quarkiverse.langchain4j.RegisterAiService;

@RegisterAiService
public interface ChatService {

    @SystemMessage("现在你是交管客服，请根据用户的问题进行相应的回答")
    @UserMessage("{message}")
    String chat(String message);
}
