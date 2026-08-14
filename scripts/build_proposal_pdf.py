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


def main() -> None:
    rl_config.invariant = 1
    regular, bold = register_fonts()
    OUT.parent.mkdir(parents=True, exist_ok=True)

    title = ParagraphStyle("title", fontName=bold, fontSize=18, leading=23,
                           textColor=colors.HexColor("#111827"), spaceAfter=6)
    subtitle = ParagraphStyle("subtitle", fontName=regular, fontSize=9.5,
                              leading=14, textColor=colors.HexColor("#4b5563"),
                              spaceAfter=8)
    heading = ParagraphStyle("heading", fontName=bold, fontSize=11, leading=15,
                             textColor=colors.HexColor("#0f766e"), spaceBefore=5,
                             spaceAfter=3)
    body = ParagraphStyle("body", fontName=regular, fontSize=9.3, leading=14,
                          textColor=colors.HexColor("#1f2937"), spaceAfter=4)
    small = ParagraphStyle("small", fontName=regular, fontSize=8.3, leading=12,
                           textColor=colors.HexColor("#374151"))

    doc = SimpleDocTemplate(str(OUT), pagesize=A4, leftMargin=18 * mm,
                            rightMargin=18 * mm, topMargin=15 * mm,
                            bottomMargin=14 * mm)
    p = lambda text, style: Paragraph(text, style)
    story = [
        p("MoonFeatureGate：MoonBit 原生功能开关与灰度发布工具库", title),
        p("申报人：魏承昌（Wccerty）｜版本：0.1.3｜方向：工程基础设施与工具链。"
          "GitHub：github.com/wccerty/MoonFeatureGate；GitLink：gitlink.org.cn/Wccerty/MoonFeatureGate。", subtitle),
        p("项目简介", heading),
        p("MoonFeatureGate 面向 MoonBit 生态提供本地功能开关、用户定向、稳定百分比 rollout、"
          "批量评估和决策原因解释。它不依赖外部 SaaS 控制台，适合服务端、WASM 示例、教学项目和上线前的可审计配置。", body),
        p("核心能力", heading),
    ]
    data = [
        [p("模块", small), p("0.1.3 交付内容", small)],
        [p("类型安全", small), p("支持 Bool、String、Int、Double 四类 FlagValue 和类型匹配检查。", small)],
        [p("Provider", small), p("支持 FeatureProvider、JSON provider、多类型 DSL、merge、diff、fingerprint 和 inventory。", small)],
        [p("治理能力", small), p("支持审计、生产策略、健康检查、配置 registry、兼容性判定、发布风险计划和纯函数部署预检。", small)],
        [p("评估能力", small), p("支持静态、disabled、target、rollout、多请求批量评估、暴露分析和隐私友好的 DecisionLedger。", small)],
        [p("工程证据", small), p("12 个真实业务形态基准场景、4-context 验收矩阵、53 项测试、跨平台 CI，非测试源码约 4,000 行。", small)],
    ]
    table = Table(data, colWidths=[32 * mm, 124 * mm])
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#ecfdf5")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.HexColor("#064e3b")),
        ("GRID", (0, 0), (-1, -1), 0.35, colors.HexColor("#d1d5db")),
        ("VALIGN", (0, 0), (-1, -1), "TOP"),
        ("LEFTPADDING", (0, 0), (-1, -1), 6),
        ("RIGHTPADDING", (0, 0), (-1, -1), 6),
        ("TOPPADDING", (0, 0), (-1, -1), 5),
        ("BOTTOMPADDING", (0, 0), (-1, -1), 5),
    ]))
    story.extend([table, Spacer(1, 5), p("验收与复现", heading)])
    story.append(p("针对预验收意见，项目使用 MoonBit 0.10.3 兼容的 CLI 包声明，严格校验 JSON schema，"
                   "补充多类型 DSL、disabled 回读、provider 审计、生产策略、配置兼容性和部署前健康检查。"
                   "基准数据为可公开的合成业务场景，不含客户数据。", body))
    story.append(p("moon fmt --check ｜ moon check --deny-warn ｜ moon check --target all ｜ moon info ｜ "
                   "moon test --deny-warn ｜ moon test --target all ｜ moon run cmd/moonfeaturegate", body))
    story.append(p("开源与维护", heading))
    story.append(p("项目使用 Apache-2.0，公开维护在 GitHub 与 GitLink，模块名为 wccerty/moonfeaturegate。"
                   "后续可在保持 evaluator API 稳定的前提下扩展 TOML、远程配置轮询、指标钩子和 Web 预览。", body))
    doc.build(story)


if __name__ == "__main__":
    main()
