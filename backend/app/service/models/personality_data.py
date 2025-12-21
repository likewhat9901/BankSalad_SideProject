"""소비 성향 유형별 정보 데이터"""

PERSONALITY_INFO = {
    "Unknown": {
        "name": "-",
        "description": "데이터가 부족하여 분석할 수 없습니다.",
        "traits": ["분석 필요"],
        "character_icon": "❓",
        "character_image": "assets/images/characters/default.png",
        "advice": "거래내역을 업로드하면 소비 성향을 분석할 수 있습니다.",
    },
    # Planning (P) 계열 - Regular (R)
    "PRHS": {
        "name": "계획왕",
        "description": "모든 소비를 계획하고, 규칙적으로 반복 소비하는 절약형",
        "traits": ["계획적", "규칙적", "습관적", "절약형"],
        "character_icon": "🎯",
        "character_image": "assets/images/characters/prhs.png",
        "advice": "이미 완벽한 소비 습관을 가지고 계시네요! 현재 패턴을 유지하세요."
    },
    "PRHE": {
        "name": "습관 소비자",
        "description": "계획적으로 규칙적인 반복 소비를 하지만 소비 규모가 큰 타입",
        "traits": ["계획적", "규칙적", "습관적", "소비형"],
        "character_icon": "📅",
        "character_image": "assets/images/characters/prhe.png",
        "advice": "반복 소비 패턴을 줄이면 큰 절약이 가능합니다."
    },
    "PRVS": {
        "name": "균형잡힌 계획가",
        "description": "계획적이고 규칙적이지만 다양한 곳에서 절약하는 타입",
        "traits": ["계획적", "규칙적", "다양성", "절약형"],
        "character_icon": "⚖️",
        "character_image": "assets/images/characters/prvs.png",
        "advice": "균형잡힌 소비 패턴입니다. 현재 수준을 유지하세요."
    },
    "PRVE": {
        "name": "시간 관리 소비자",
        "description": "계획적이고 규칙적인 시간에 다양한 곳에서 소비",
        "traits": ["계획적", "규칙적", "다양성", "소비형"],
        "character_icon": "⏰",
        "character_image": "assets/images/characters/prve.png",
        "advice": "특정 시간대 소비를 줄이면 절약이 가능합니다."
    },
    # Planning (P) 계열 - Irregular (U)
    "PUHS": {
        "name": "유연한 절약가",
        "description": "계획적이지만 시간이 자유롭고 반복 소비로 절약하는 타입",
        "traits": ["계획적", "불규칙", "습관적", "절약형"],
        "character_icon": "💰",
        "character_image": "assets/images/characters/puhs.png",
        "advice": "유연하면서도 절약하는 좋은 패턴입니다."
    },
    "PUHE": {
        "name": "변덕 계획가",
        "description": "계획은 있지만 시간이 불규칙하고 반복 소비가 많은 타입",
        "traits": ["계획적", "불규칙", "습관적", "소비형"],
        "character_icon": "🎲",
        "character_image": "assets/images/characters/puhe.png",
        "advice": "반복 소비 패턴을 분석해서 줄여보세요."
    },
    "PUVS": {
        "name": "자유로운 절약가",
        "description": "계획적이지만 자유롭고 다양한 곳에서 절약하는 타입",
        "traits": ["계획적", "불규칙", "다양성", "절약형"],
        "character_icon": "🌊",
        "character_image": "assets/images/characters/puvs.png",
        "advice": "자유롭게 소비하면서도 절약하는 이상적인 패턴입니다."
    },
    "PUVE": {
        "name": "유연한 소비자",
        "description": "계획은 있지만 시간과 장소가 자유롭고 소비가 많은 타입",
        "traits": ["계획적", "불규칙", "다양성", "소비형"],
        "character_icon": "🎨",
        "character_image": "assets/images/characters/puve.png",
        "advice": "소비 패턴을 분석해서 불필요한 지출을 줄여보세요."
    },
    # Impulse (I) 계열 - Regular (R)
    "IRHS": {
        "name": "습관 충동가",
        "description": "충동적이지만 특정 습관이 있어서 절약하는 타입",
        "traits": ["충동적", "규칙적", "습관적", "절약형"],
        "character_icon": "⚡",
        "character_image": "assets/images/characters/irhs.png",
        "advice": "충동 소비를 줄이면 더 큰 절약이 가능합니다."
    },
    "IRHE": {
        "name": "반복 충동 소비자",
        "description": "충동적으로 특정 시간대에 반복 소비하는 타입",
        "traits": ["충동적", "규칙적", "습관적", "소비형"],
        "character_icon": "🔥",
        "character_image": "assets/images/characters/irhe.png",
        "advice": "특정 시간대의 충동 소비를 주의하세요."
    },
    "IRVS": {
        "name": "시간 충동 절약가",
        "description": "충동적이지만 특정 시간대에 다양한 곳에서 절약하는 타입",
        "traits": ["충동적", "규칙적", "다양성", "절약형"],
        "character_icon": "🌙",
        "character_image": "assets/images/characters/irvs.png",
        "advice": "충동 소비 시간대를 피하면 더 절약할 수 있습니다."
    },
    "IRVE": {
        "name": "야간 충동 소비자",
        "description": "충동적으로 특정 시간대에 다양한 곳에서 소비하는 타입",
        "traits": ["충동적", "규칙적", "다양성", "소비형"],
        "character_icon": "🌃",
        "character_image": "assets/images/characters/irve.png",
        "advice": "야간 충동 소비가 많습니다. 계획을 세워보세요."
    },
    # Impulse (I) 계열 - Irregular (U)
    "IUHS": {
        "name": "무작위 절약가",
        "description": "완전 자유롭지만 반복 소비로 절약하는 타입",
        "traits": ["충동적", "불규칙", "습관적", "절약형"],
        "character_icon": "🎲",
        "character_image": "assets/images/characters/iuhs.png",
        "advice": "반복 소비를 줄이면 더 절약할 수 있습니다."
    },
    "IUHE": {
        "name": "완전 충동 소비자",
        "description": "충동적이고 불규칙하며 반복 소비가 많은 타입",
        "traits": ["충동적", "불규칙", "습관적", "소비형"],
        "character_icon": "💥",
        "character_image": "assets/images/characters/iuhe.png",
        "advice": "소비 패턴을 분석하고 계획을 세워보세요."
    },
    "IUVS": {
        "name": "자유로운 절약가",
        "description": "완전 자유롭게 다양한 곳에서 절약하는 타입",
        "traits": ["충동적", "불규칙", "다양성", "절약형"],
        "character_icon": "🌈",
        "character_image": "assets/images/characters/iuvs.png",
        "advice": "자유롭게 소비하면서도 절약하는 좋은 패턴입니다."
    },
    "IUVE": {
        "name": "완전 자유 소비자",
        "description": "충동적이고 불규칙하며 다양한 곳에서 자유롭게 소비",
        "traits": ["충동적", "불규칙", "다양성", "소비형"],
        "character_icon": "🚀",
        "character_image": "assets/images/characters/iuve.png",
        "advice": "소비 패턴을 분석해서 계획을 세워보는 건 어떨까요?"
    },
}