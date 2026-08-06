import hashlib
from pathlib import Path
from typing import Tuple

from reportlab import rl_config
from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase import pdfdoc
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import Paragraph, SimpleDocTemplate, Spacer, Table, TableStyle


ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "docs" / "proposal.pdf"
FONT = Path(r"C:\Windows\Fonts\simhei.ttf")


def md5_compat(*args, **kwargs):
    kwargs.pop("usedforsecurity", None)
    return hashlib.md5(*args, **kwargs)


pdfdoc.md5 = md5_compat


def register_fonts() -> Tuple[str, str]:
    regular = "SimHei"
    bold = "SimHei-Bold"
    pdfmetrics.registerFont(TTFont(regular, str(FONT)))
    pdfmetrics.registerFont(TTFont(bold, str(FONT)))
    return regular, bold


def paragraph(text: str, style: ParagraphStyle) -> Paragraph:
    return Paragraph(text, style)


def main() -> None:
    rl_config.invariant = 1
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
    heading = ParagraphStyle(
        "heading",
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
        paragraph("MoonFeatureGate：MoonBit 原生功能开关与灰度发布工具库", title),
        paragraph(
            "申报人：魏承昌（Wccerty）｜版本：0.1.1｜方向：工程基础设施与工具链。"
            "GitHub：github.com/wccerty/MoonFeatureGate；GitLink：gitlink.org.cn/Wccerty/MoonFeatureGate。",
            subtitle,
        ),
        paragraph("项目简介", heading),
        paragraph(
            "MoonFeatureGate 面向 MoonBit 生态提供本地功能开关、用户定向、稳定百分比 rollout "
            "和决策原因解释。它不依赖外部 SaaS 控制台，适合服务端、WASM 示例、教学项目和上线前的可审计配置。",
            body,
        ),
        paragraph("核心能力", heading),
    ]

    data = [
        [paragraph("模块", small), paragraph("0.1.1 交付内容", small)],
        [paragraph("FlagValue", small), paragraph("支持 Bool、String、Int、Double 四类类型安全值。", small)],
        [paragraph("EvalContext", small), paragraph("支持 targeting_key 和属性 Map，可表达用户、环境和请求上下文。", small)],
        [paragraph("Provider", small), paragraph("支持本地 provider、FeatureProvider trait、JSON provider 和文本 DSL。", small)],
        [paragraph("Evaluator", small), paragraph("返回值、flag_key 和 default / disabled / target / rollout 等原因。", small)],
        [paragraph("工程化", small), paragraph("包含 CLI demo、黑盒/白盒测试、空 Map/类型不匹配/畸形 JSON 边界测试和跨平台 CI。", small)],
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
            paragraph("验收修订", heading),
            paragraph(
                "针对预验收意见，项目已将空 Map 改为显式 Map([])，将 CLI 包改为 "
                "pkgtype(kind: \"executable\")，并在 README 中补充 MoonBit 0.10.3 安装、"
                "moon add、严格验证和可执行 demo 步骤。JSON provider 现在拒绝错误根结构、"
                "字段类型、目标字段和 rollout 范围，避免静默丢弃错误配置。",
                body,
            ),
            paragraph("复现命令", heading),
            paragraph(
                "moon fmt --check ｜ moon check --deny-warn ｜ moon info ｜ "
                "moon test --deny-warn ｜ moon run cmd/moonfeaturegate。"
                "CI 额外覆盖 native 测试与 coverage analyze。",
                body,
            ),
            paragraph("开源与维护", heading),
            paragraph(
                "项目使用 Apache-2.0，公开维护在 GitHub 与 GitLink，模块名为 "
                "wccerty/moonfeaturegate。后续可在保持 evaluator API 稳定的前提下扩展 TOML、"
                "远程配置轮询、指标钩子和 Web 预览。",
                body,
            ),
        ]
    )
    doc.build(story)


if __name__ == "__main__":
    main()
