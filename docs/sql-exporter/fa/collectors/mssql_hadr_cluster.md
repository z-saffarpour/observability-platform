# mssql_hadr_cluster

## خلاصه

- فایل: `collector/mssql_hadr_cluster.collector.yml`
- نام collector: `mssql_hadr_cluster`
- حداقل فاصله اجرا: `30s`
- تعداد metric: `11`
- query_refهای مشترک: `mssql_hadr_instance_flags`, `mssql_hadr_cluster`, `mssql_hadr_cluster_members`, `mssql_hadr_listeners`, `mssql_hadr_listener_ips`, `mssql_hadr_fci_nodes`
- پروفایل‌ها: `oltp`, `dwh` (کنار `mssql_alwayson`)

## هدف و کاربرد

مکمل `mssql_alwayson` (تأخیر/همگام‌سازی replica) با سیگنال‌های کلاستر و Listener:

- فهرست AG Listener (DNS، پورت، پرچم conformant)
- وضعیت IP لیسنر (ONLINE / OFFLINE / PENDING / FAILED)
- نوع و وضعیت quorum در WSFC
- وضعیت اعضا و رأی quorum
- وضعیت نودهای FCI و owner فعلی
- پرچم‌های instance: `IsClustered`، `IsHadrEnabled`

## مجوزها و پیش‌نیازها

- `VIEW SERVER STATE`
- `VIEW ANY DEFINITION` (برای catalog viewهای listener)

اگر AG / WSFC / FCI نباشد خروجی خالی است (یا پرچم‌ها `0`) و scrape نباید fail شود.

## متریک‌ها

| متریک | نوع | برچسب‌ها / مقادیر | منبع | توضیح |
|---|---|---|---|---|
| `mssql_hadr_is_clustered` | `gauge` | — | `is_clustered` | query_ref=`mssql_hadr_instance_flags` | ۱ اگر instance از نوع FCI باشد. |
| `mssql_hadr_is_hadr_enabled` | `gauge` | — | `is_hadr_enabled` | query_ref=`mssql_hadr_instance_flags` | ۱ اگر Always On فعال باشد. |
| `mssql_hadr_cluster_quorum_state` | `gauge` | `cluster_name`, `quorum_type_desc`, `quorum_state_desc` | `quorum_state` | query_ref=`mssql_hadr_cluster` | وضعیت quorum WSFC (۰=نامشخص، ۱=عادی، ۲=اجباری). |
| `mssql_hadr_cluster_quorum_type` | `gauge` | `cluster_name`, `quorum_type_desc`, `quorum_state_desc` | `quorum_type` | query_ref=`mssql_hadr_cluster` | نوع quorum WSFC. |
| `mssql_hadr_cluster_member_state` | `gauge` | `cluster_name`, `member_name`, `member_type_desc`, `member_state_desc` | `member_state` | query_ref=`mssql_hadr_cluster_members` | وضعیت عضو کلاستر (۱=up). |
| `mssql_hadr_cluster_member_quorum_votes` | `gauge` | `cluster_name`, `member_name`, `member_type_desc`, `member_state_desc` | `number_of_quorum_votes` | query_ref=`mssql_hadr_cluster_members` | تعداد رأی quorum عضو. |
| `mssql_hadr_listener_info` | `gauge` | `availability_group_name`, `dns_name`, `is_conformant` | `info` | query_ref=`mssql_hadr_listeners` | ۱ به‌ازای هر AG Listener. |
| `mssql_hadr_listener_port` | `gauge` | `availability_group_name`, `dns_name` | `port` | query_ref=`mssql_hadr_listeners` | پورت TCP لیسنر. |
| `mssql_hadr_listener_ip_state` | `gauge` | `availability_group_name`, `dns_name`, `ip_address`, `state_desc`, `is_dhcp` | `ip_state` | query_ref=`mssql_hadr_listener_ips` | وضعیت IP لیسنر (۰=ONLINE، ۱=OFFLINE، …، ۱-=نامشخص/fallback). اگر IP کاتالوگ خالی باشد از `ip_configuration_string_from_cluster` یا `(dhcp)`/`(unknown)` استفاده می‌شود. |
| `mssql_hadr_fci_node_status` | `gauge` | `node_name`, `status_description` | `status` | query_ref=`mssql_hadr_fci_nodes` | وضعیت نود FCI (۰=up). |
| `mssql_hadr_fci_is_current_owner` | `gauge` | `node_name`, `status_description` | `is_current_owner` | query_ref=`mssql_hadr_fci_nodes` | ۱ اگر نود مالک فعلی resource کلاستر SQL باشد. |

## نمونه آلرت

```promql
mssql_hadr_cluster_quorum_state != 1
mssql_hadr_cluster_member_state != 1
mssql_hadr_listener_ip_state != 0
mssql_hadr_fci_node_status != 0
```

## نکات عملیاتی

- برای پوشش کامل HADR همراه با `mssql_alwayson` استفاده شود.
- داشبورد `sqlx-hadr-cluster`: لیست **Server** همه hostهای HADR/Always On را شامل می‌شود (نه فقط WSFC با `cluster_name`). hostهای بدون متادیتای WSFC در جدول **HADR without WSFC cluster row** با لینک **AlwaysOn** دیده می‌شوند.
- فاصله ۳۰ ثانیه برای quorum/listener کافی است.
- کاردینالیتی پایین است (تعداد کم listener و عضو کلاستر).
- سرورهای روی پروفایل **`core`** collectorهای `mssql_hadr_cluster` و `mssql_alwayson` را scrape نمی‌کنند؛ برای AG از `oltp`/`dwh` استفاده کنید.
