local s,id=GetID()
s.listed_names={13131313}
function s.initial_effect(c)
	-- Archetype Identity: Umbra Witch (0x7f6)
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_ADD_SETCODE)
	e0:SetValue(0x7f6)
	c:RegisterEffect(e0)

	-- 1. Quick Effect: Special Summon "Infernal Demon" from GY
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetProperty(EFFECT_FLAG_CARD_TARGET)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	-- High-priority timing to ensure it works during opponent's turn
	e1:SetHintTiming(0,TIMINGS_CHECK_MONSTER+TIMING_END_PHASE)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- 2. ATK Gain: Equal to Bayonetta's current ATK
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e2:SetRange(LOCATION_MZONE)
	e2:SetCode(EFFECT_UPDATE_ATTACK)
	e2:SetValue(s.atkval)
	c:RegisterEffect(e2)

	-- 3. Protection: Opponent cannot target this card while you control a Demon
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetCode(EFFECT_CANNOT_BE_EFFECT_TARGET)
	e3:SetCondition(s.protcon)
	e3:SetValue(aux.tgoval)
	c:RegisterEffect(e3)
	-- Protection from being a battle target
	local e4=e3:Clone()
	e4:SetCode(EFFECT_CANNOT_BE_BATTLE_TARGET)
	e4:SetValue(aux.imval1)
	c:RegisterEffect(e4)
end

s.SET_INFERNAL_DEMON = 0x704
s.CARD_BAYONETTA = 13131313

-- Filter for Infernal Demons (Checks Archetype 0x704 or Butterfly/Gomorrah IDs)
function s.demfilter(c)
	return c:IsFaceup() and (c:IsSetCard(s.SET_INFERNAL_DEMON) or c:IsCode(13131315, 13131317))
end

-- 1. Special Summon Logic
function s.spfilter(c,e,tp)
	return (c:IsSetCard(s.SET_INFERNAL_DEMON) or c:IsCode(13131315, 13131317)) 
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then return chkc:IsLocation(LOCATION_GRAVE) and chkc:IsControler(tp) and s.spfilter(chkc,e,tp) end
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingTarget(s.spfilter,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,g,1,0,0)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local tc=Duel.GetFirstTarget()
	if tc and tc:IsRelateToEffect(e) then
		Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)
	end
end

-- 2. ATK Gain Logic (Calculates total ATK of all Bayonetta on your field)
function s.atkval(e,c)
	local g=Duel.GetMatchingGroup(Card.IsCode,e:GetHandlerPlayer(),LOCATION_MZONE,0,nil,s.CARD_BAYONETTA)
	local atk=0
	local tc=g:GetFirst()
	while tc do
		atk=atk+tc:GetAttack()
		tc=g:GetNext()
	end
	return atk
end

-- 3. Protection Logic
function s.protcon(e)
	return Duel.IsExistingMatchingCard(s.demfilter,e:GetHandlerPlayer(),LOCATION_MZONE,0,1,nil)
end