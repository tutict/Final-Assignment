package finalassignmentbackend.config.route;

import jakarta.enterprise.context.ApplicationScoped;
import org.apache.camel.builder.RouteBuilder;
import org.eclipse.microprofile.config.inject.ConfigProperty;

@ApplicationScoped
public class NetWorkRoute extends RouteBuilder {

    @ConfigProperty(name = "server.port", defaultValue = "8080")
    int port;

    @ConfigProperty(name = "backend.url")
    String backendUrl;

    private final String finalUrl = backendUrl + ":" + port;

    @Override
    public void configure() {
        // 全局错误处理
        onException(Exception.class)
                .log("处理消息时发生错误: ${exception.message}")
                .handled(true)
                .setBody().constant("内部服务器错误")
                .setHeader("Content-Type", constant("text/plain"))
                .setHeader("Content-Length", simple("body.length()"))
                .setHeader("Status", constant(500));

        // WebSocket 接收消息并转发到后端 WebSocket 控制器
        from(EventBusAddress.WEBSOCKET_CONNECTION)
                .log("收到来自 WebSocket 的消息: ${body}")
                .to(finalUrl)
                .log("消息已转发到后端 WebSocket 控制器");

        // SockJS 客户端接收消息并转发到后端 HTTP 控制器
        from(EventBusAddress.CLIENT_TO_SERVER)
                .log("收到来自 SockJS 客户端的消息: ${body}")
                .to(finalUrl)
                .log("消息已转发到后端 HTTP 控制器");

        // 后端控制器响应并发送回 SockJS 客户端
        from("direct:server.to.client")
                .log("收到来自后端控制器的响应: ${body}")
                .to(EventBusAddress.SERVER_TO_CLIENT);
    }
}
