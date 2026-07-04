from pathlib import Path

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "proposal.pdf"
FONT = Path(r"C:\Windows\Fonts\simhei.ttf")
BOLD_FONT = Path(r"C:\Windows\Fonts\simhei.ttf")


def register_fonts() -> tuple[str, str]:
    regular = "NotoSansSC"
    bold = "NotoSansSC-Bold"
    pdfmetrics.registerFont(TTFont(regular, str(FONT)))
    pdfmetrics.registerFont(TTFont(bold, str(BOLD_FONT)))
    return regular, bold


def p(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text, style)


def main() -> None:
    regular, bold = register_fonts()
    OUT.parent.mkdir(parents=True, exist_ok=True)

    title = ParagraphStyle(
        "title",
        fontName=bold,
        fontSize=18,
        leading=23,
        textColor=colors.HexColor("#111827"),
        spaceAfter=6,
    )
    subtitle = ParagraphStyle(
        "subtitle",
        fontName=regular,
        fontSize=9.5,
        leading=14,
        textColor=colors.HexColor("#4b5563"),
        spaceAfter=8,
    )
    h2 = ParagraphStyle(
        "h2",
        fontName=bold,
        fontSize=11,
        leading=15,
        textColor=colors.HexColor("#0f766e"),
        spaceBefore=5,
        spaceAfter=3,
    )
    body = ParagraphStyle(
        "body",
        fontName=regular,
        fontSize=9.3,
        leading=14,
        textColor=colors.HexColor("#1f2937"),
        spaceAfter=4,
    )
    small = ParagraphStyle(
        "small",
        fontName=regular,
        fontSize=8.3,
        leading=12,
        textColor=colors.HexColor("#374151"),
    )

    doc = SimpleDocTemplate(
        str(OUT),
        pagesize=A4,
        leftMargin=18 * mm,
        rightMargin=18 * mm,
        topMargin=15 * mm,
        bottomMargin=14 * mm,
    )

    story = [
        p("MoonFeatureGate：MoonBit 原生特性开关与灰度发布工具库", title),
        p(
            "项目方向：工程基础设施与工具链 / 配置治理 / 渐进式发布。"
            "GitHub：github.com/Lyhdsba/MoonFeatureGate；GitLink 同名仓库同步。",
            subtitle,
        ),
        p("项目简介", h2),
        p(
            "MoonFeatureGate 面向 MoonBit 生态提供本地特性开关、用户定向、稳定百分比分桶和命中原因解释。"
            "它不依赖外部 SaaS 控制台，适合 MoonBit 服务端示例、WASM 演示、教学项目和基础设施库在上线前做可审查的功能灰度与配置策略管理。",
            body,
        ),
        p("为什么值得做", h2),
        p(
            "特性开关是成熟工程体系中的常见能力，但 MoonBit 生态目前更集中在解析器、日志、数据库、UI、Tracing 等方向。"
            "Mooncakes 关键词检索未发现直接的 feature flag / OpenFeature / rollout 同类包；本项目补齐的是发布风险控制与配置治理这一基础能力。",
            body,
        ),
        p("核心功能边界", h2),
    ]

    data = [
        [p("模块", small), p("首版交付", small)],
        [p("FlagValue", small), p("bool、string、int、double 等类型化值，稳定文本输出。", small)],
        [p("EvalContext", small), p("targeting_key 与属性 Map，用于用户、环境、请求等上下文。", small)],
        [p("Provider", small), p("本地内存 provider，支持静态 bool flag、target 规则、百分比 rollout。", small)],
        [p("Evaluator", small), p("返回 value、flag_key、reason，解释 default / static / target / rollout 等路径。", small)],
        [p("DSL + CLI", small), p("简洁配置文本解析、示例配置、可运行 CLI demo 与 CI 验证。", small)],
    ]
    table = Table(data, colWidths=[32 * mm, 124 * mm])
    table.setStyle(
        TableStyle(
            [
                ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#ecfdf5")),
                ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#064e3b")),
                ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#d1d5db")),
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 6),
                ("RIGHTPADDING", (0, 0), (-1, -1), 6),
                ("TOPPADDING", (0, 0), (-1, -1), 5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
            ]
        )
    )
    story.extend(
        [
            table,
            Spacer(1, 5),
            p("实现计划", h2),
            p(
                "已经完成项目骨架、类型化值、默认回退、稳定分桶、属性定向、文本配置解析、CLI demo、测试和 CI。"
                "后续验收前继续补充 Mooncakes 发布信息、更多配置样例和 README 使用说明，并保持 GitHub 与 GitLink 仓库同步。",
                body,
            ),
            p("最终交付", h2),
            p(
                "公开源码仓库、10-20 个有效 commits、Apache-2.0 许可证、README、示例配置、设计文档、验收清单、CI、"
                "可运行 MoonBit 测试与 CLI demo、Mooncakes 发布或 dry-run 记录。",
                body,
            ),
            p("原创性说明", h2),
            p(
                "本项目为原创 MoonBit 工程库，不移植单个既有项目。设计参考成熟特性开关领域的通用概念和 OpenFeature 的厂商无关思想，"
                "首版聚焦 MoonBit 本地评估能力，后续可扩展 OpenFeature 风格 provider、远程配置、指标导出和 Web 预览。",
                body,
            ),
        ]
    )
    doc.build(story)


if __name__ == "__main__":
    main()
