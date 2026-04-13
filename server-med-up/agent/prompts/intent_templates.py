"""Per-intent prompt snippets injected after system prompt."""

from agent.intents.definitions import Intent

INTENT_SNIPPETS: dict[str, str] = {
    Intent.GREETING: "User chao hoi. Tom tat tinh trang + thuoc hom nay + lieu tiep theo.",
    Intent.MISSED_DOSE_GUIDANCE: "User quen uong thuoc. Empathy + goi y uong bu neu con trong khung gio + log_dose missed.",
    Intent.SIDE_EFFECT_CHECK: "User hoi tac dung phu. Dung RAG context, liet ke pho bien nhat, khuyen theo doi.",
    Intent.DRUG_DRUG_INTERACTION: "User hoi tuong tac thuoc. Kiem tra RAG, canh bao muc do, khuyen cach gio.",
    Intent.CHECK_MED_SCHEDULE: "User hoi lich uong. Liet ke thuoc + gio + trang thai (da uong/chua).",
    Intent.OVERDOSE_GUIDANCE: "KHAN CAP. Huong dan so cuu + goi 115 + lien he bac si NGAY.",
    Intent.EMERGENCY_SYMPTOM: "KHAN CAP. Khuyen lien he co so y te / cap cuu ngay lap tuc.",
    Intent.TREATMENT_TRACKING: "User hoi tien do tuan thu. Dua vao adherence summary, dong vien hoac canh bao nhe.",
    Intent.DRUG_INFO_GENERAL: "User hoi thong tin thuoc. Dung RAG context, tom tat cong dung + lieu + cach dung.",
    Intent.CONTACT_DOCTOR: "User muon lien he bac si. Cung cap thong tin lien lac neu co, khuyen gap truc tiep.",
}


def get_intent_snippet(intent: str) -> str:
    return INTENT_SNIPPETS.get(intent, "")
