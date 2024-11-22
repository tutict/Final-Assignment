package finalassignmentbackend.config;

import com.baomidou.mybatisplus.extension.plugins.inner.OptimisticLockerInnerInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.PaginationInnerInterceptor;
import io.quarkus.arc.DefaultBean;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.enterprise.inject.Produces;

@ApplicationScoped
public class MybatisPlusConfig {

    /**
     * 分页插件
     *
     * @return PaginationInnerInterceptor实例
     */
    @Produces
    @DefaultBean
    public PaginationInnerInterceptor paginationInnerInterceptor() {
        PaginationInnerInterceptor interceptor = new PaginationInnerInterceptor();
        interceptor.setOverflow(true); // 设置请求页数大于总页数时回到首页
        interceptor.setMaxLimit(500L); // 设置单页最大数量限制，防止大数据量请求
        return interceptor;
    }

    /**
     * 乐观锁插件
     *
     * @return OptimisticLockerInnerInterceptor实例
     */
    @Produces
    @DefaultBean
    public OptimisticLockerInnerInterceptor optimisticLockerInnerInterceptor() {
        return new OptimisticLockerInnerInterceptor();
    }
}
