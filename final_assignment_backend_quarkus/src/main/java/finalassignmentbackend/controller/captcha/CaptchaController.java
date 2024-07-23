package finalassignmentbackend.controller.captcha;


import com.baomidou.mybatisplus.core.toolkit.StringUtils;
import jakarta.inject.Inject;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.Context;
import jakarta.ws.rs.core.MediaType;

@Path("/eventbus/captcha")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class CaptchaController {

    @Inject
    CaptchaService captchaService;

    @POST
    @Path("/get")
    public ResponseModel get(CaptchaVO data, @Context HttpServletRequest request) {
        assert request.getRemoteHost() != null;
        data.setBrowserInfo(getRemoteId(request));
        return captchaService.get(data);
    }

    @POST
    @Path("/check")
    public ResponseModel check(CaptchaVO data, @Context HttpServletRequest request) {
        data.setBrowserInfo(getRemoteId(request));
        return captchaService.check(data);
    }

    @POST
    @Path("/verify")
    public ResponseModel verify(CaptchaVO data, @Context HttpServletRequest request) {
        return captchaService.verification(data);
    }

    public static String getRemoteId(HttpServletRequest request) {
        String xfwd = request.getHeader("X-Forwarded-For");
        String ip = getRemoteIpFromXfwd(xfwd);
        String ua = request.getHeader("user-agent");
        if (StringUtils.isNotBlank(ip)) {
            return ip + ua;
        }
        return request.getRemoteAddr() + ua;
    }

    private static String getRemoteIpFromXfwd(String xfwd) {
        if (StringUtils.isNotBlank(xfwd)) {
            String[] ipList = xfwd.split(",");
            return StringUtils.trim(ipList[0]);
        }
        return null;
    }

}