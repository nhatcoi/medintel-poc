"""Intent enum -- 50 intents grouped by domain (from top-intent.md)."""

from enum import Enum


class Intent(str, Enum):
    # -- Schedule & dosage (10) --
    CHECK_MED_SCHEDULE = "check_med_schedule"
    CHECK_DOSE_AMOUNT = "check_dose_amount"
    MISSED_DOSE_GUIDANCE = "missed_dose_guidance"
    SKIP_DOSE_GUIDANCE = "skip_dose_guidance"
    ADJUST_DOSE = "adjust_dose"
    DOSE_FREQUENCY = "dose_frequency"
    DOSE_TIME_CHANGE = "dose_time_change"
    DOSE_BEFORE_AFTER_MEAL = "dose_before_after_meal"
    DOSE_WITH_WATER_FOOD = "dose_with_water_food"
    DOSE_FORM_INSTRUCTIONS = "dose_form_instructions"

    # -- Side effects & symptoms (8) --
    SIDE_EFFECT_CHECK = "side_effect_check"
    SERIOUS_SIDE_EFFECT_ALERT = "serious_side_effect_alert"
    MILD_SIDE_EFFECT_INFO = "mild_side_effect_info"
    SIDE_EFFECT_DURATION = "side_effect_duration"
    SIDE_EFFECT_MANAGEMENT = "side_effect_management"
    UNEXPECTED_SYMPTOM_CHECK = "unexpected_symptom_check"
    ALLERGIC_REACTION_GUIDANCE = "allergic_reaction_guidance"
    REPORT_SIDE_EFFECT = "report_side_effect"

    # -- Drug interactions (6) --
    DRUG_DRUG_INTERACTION = "drug_drug_interaction"
    DRUG_FOOD_INTERACTION = "drug_food_interaction"
    DRUG_ALCOHOL_INTERACTION = "drug_alcohol_interaction"
    DRUG_SUPPLEMENT_INTERACTION = "drug_supplement_interaction"
    CONTRAINDICATION_CHECK = "contraindication_check"
    PREGNANCY_LACTATION_SAFE = "pregnancy_lactation_safe"

    # -- Adherence & effectiveness (6) --
    TREATMENT_EFFECTIVENESS = "treatment_effectiveness"
    TREATMENT_DURATION = "treatment_duration"
    CAN_STOP_EARLY = "can_stop_early"
    TREATMENT_REMINDER_SETUP = "treatment_reminder_setup"
    TREATMENT_TRACKING = "treatment_tracking"
    TREATMENT_COMPLIANCE_TIPS = "treatment_compliance_tips"

    # -- Storage (4) --
    STORAGE_INSTRUCTIONS = "storage_instructions"
    EXPIRY_CHECK = "expiry_check"
    TEMPERATURE_REQUIREMENT = "temperature_requirement"
    HUMIDITY_LIGHT_SENSITIVITY = "humidity_light_sensitivity"

    # -- Drug & disease info (8) --
    DRUG_INFO_GENERAL = "drug_info_general"
    DRUG_COMPOSITION = "drug_composition"
    DRUG_BRAND_GENERIC = "drug_brand_generic"
    DISEASE_INFO_GENERAL = "disease_info_general"
    DISEASE_SYMPTOMS_CHECK = "disease_symptoms_check"
    DISEASE_RISK_FACTORS = "disease_risk_factors"
    DISEASE_PREVENTION = "disease_prevention"
    TREATMENT_OPTIONS = "treatment_options"

    # -- Special populations (4) --
    PEDIATRIC_USE = "pediatric_use"
    ELDERLY_USE = "elderly_use"
    PREGNANCY_USE = "pregnancy_use"
    CHRONIC_DISEASE_USE = "chronic_disease_use"

    # -- Emergency (4) --
    OVERDOSE_GUIDANCE = "overdose_guidance"
    EMERGENCY_SYMPTOM = "emergency_symptom"
    POISONING_GUIDANCE = "poisoning_guidance"
    CONTACT_DOCTOR = "contact_doctor"

    # -- Meta --
    GREETING = "greeting"
    SMALL_TALK = "small_talk"
    UNKNOWN = "unknown"


INTENTS_NEEDING_RAG = frozenset({
    Intent.SIDE_EFFECT_CHECK, Intent.SERIOUS_SIDE_EFFECT_ALERT,
    Intent.MILD_SIDE_EFFECT_INFO, Intent.SIDE_EFFECT_DURATION,
    Intent.SIDE_EFFECT_MANAGEMENT, Intent.ALLERGIC_REACTION_GUIDANCE,
    Intent.DRUG_DRUG_INTERACTION, Intent.DRUG_FOOD_INTERACTION,
    Intent.DRUG_ALCOHOL_INTERACTION, Intent.DRUG_SUPPLEMENT_INTERACTION,
    Intent.CONTRAINDICATION_CHECK, Intent.PREGNANCY_LACTATION_SAFE,
    Intent.DRUG_INFO_GENERAL, Intent.DRUG_COMPOSITION, Intent.DRUG_BRAND_GENERIC,
    Intent.STORAGE_INSTRUCTIONS, Intent.TEMPERATURE_REQUIREMENT,
    Intent.DOSE_BEFORE_AFTER_MEAL, Intent.DOSE_WITH_WATER_FOOD,
    Intent.DOSE_FORM_INSTRUCTIONS, Intent.TREATMENT_OPTIONS,
    Intent.OVERDOSE_GUIDANCE, Intent.POISONING_GUIDANCE,
    Intent.DISEASE_INFO_GENERAL, Intent.DISEASE_SYMPTOMS_CHECK,
    Intent.DISEASE_RISK_FACTORS, Intent.DISEASE_PREVENTION,
    Intent.PEDIATRIC_USE, Intent.ELDERLY_USE, Intent.PREGNANCY_USE,
    Intent.CHRONIC_DISEASE_USE, Intent.TREATMENT_EFFECTIVENESS,
    Intent.TREATMENT_DURATION, Intent.CAN_STOP_EARLY,
    Intent.HUMIDITY_LIGHT_SENSITIVITY, Intent.EXPIRY_CHECK,
})
