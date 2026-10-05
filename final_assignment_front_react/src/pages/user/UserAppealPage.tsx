import { useMemo } from "react";
import { useQuery } from "@tanstack/react-query";
import CrudPage from "../shared/CrudPage";
import { entityConfigs } from "../../config/entities";
import { useUserAppeals } from "../../hooks/useUserAppeals";
import { useUserOffenses } from "../../hooks/useUserDashboard";
import { useAgentPrefill, hasBusinessPrefill } from "../../hooks/useAgentPrefill";
import { getCurrentProfile } from "../../api/profile";
import type { EntityConfig } from "../../config/entityTypes";

/**
 * 用户申诉页。没有本人违法记录时不提供新增，避免提交后被后端拒绝。
 */
export default function UserAppealPage() {
  const appealsQuery = useUserAppeals();
  const prefill = useAgentPrefill();
  const prefillHint = hasBusinessPrefill(prefill) ? prefill.businessNumber : null;
  const profileQuery = useQuery({
    queryKey: ["profile", "me"],
    queryFn: getCurrentProfile,
  });
  const offensesQuery = useUserOffenses(profileQuery.data?.driverId);
  const canAppeal = (offensesQuery.data?.length ?? 0) > 0;

  const config: EntityConfig = useMemo(
    () => ({
      ...entityConfigs.appeals,
      layout: "cards",
      label: "我的申诉",
      hideCreate: !canAppeal,
      queryResult: appealsQuery,
      errorRowMessage: (row) =>
        (row as { __fetchError?: boolean })?.__fetchError
          ? "申诉信息加载失败，请刷新重试"
          : null,
    }),
    [appealsQuery, canAppeal],
  );

  return (
    <>
      {prefillHint ? (
        <div className="panel" role="status">
          <h3>AI 助手已为您定位</h3>
          <p>关联业务编号：<strong>{prefillHint}</strong>，请在申诉表单中引用该编号。</p>
        </div>
      ) : null}
      {!profileQuery.isLoading && !offensesQuery.isLoading && !canAppeal ? (
        <div className="panel" role="status">
          <p>当前没有可申诉的违法记录。产生违法后才能提交申诉。</p>
        </div>
      ) : null}
      <CrudPage config={config} />
    </>
  );
}
