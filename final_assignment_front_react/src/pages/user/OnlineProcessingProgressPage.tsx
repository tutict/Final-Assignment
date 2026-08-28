/**
 * 用户在线办理进度页，对齐 Flutter OnlineProcessingProgress。
 * 复用 ProgressMessageList（用户端只读 + 筛选，无管理操作）。
 */
import PageLayout from '../../components/PageLayout';
import ProgressMessageList from '../../components/ProgressMessageList';

export default function OnlineProcessingProgressPage() {
  return (
    <PageLayout title="进度消息" subtitle="查看申诉、缴费和业务办理后的处理进展">
      <ProgressMessageList
        title="进度消息"
        subtitle="查看申诉、缴费和业务办理后的处理进展。"
        roleLabel="驾驶员端"
        emptyMessage="暂无申诉办理进度。提交申诉或办理业务后，处理进展会显示在这里。"
      />
    </PageLayout>
  );
}
