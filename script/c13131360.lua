--Sin Gomorrah, Font of Devastation
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()

	--Fusion materials
	Fusion.AddProcCode2(c,13131313,13131314,true,true) -- Bayonetta + Gomorrah

	--Must be Special Summoned by "Deadly Sin"
	local e0=Effect.CreateEffect(c)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE+EFFECT_FLAG_UNCOPYABLE)
	e0:SetCode(EFFECT_SPSUMMON_CONDITION)
	e0:SetValue(s.splimit)
	c:RegisterEffect(e0)

	--Unaffected by other card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_IMMUNE_EFFECT)
	e1:SetValue(s.efilter)
	c:RegisterEffect(e1)

	--Cannot be Tributed
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_UNRELEASABLE_SUM)
	e2:SetValue(1)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EFFECT_UNRELEASABLE_NONSUM)
	c:RegisterEffect(e3)

	--On summon: send all other monsters you control to GY
	local e4=Effect.CreateEffect(c)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_F)
	e4:SetCode(EVENT_SPSUMMON_SUCCESS)
	e4:SetCountLimit(1,id)
	e4:SetOperation(s.tgop)
	c:RegisterEffect(e4)

	--Start of Battle Phase: destroy all opponent cards
	local e5=Effect.CreateEffect(c)
	e5:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e5:SetCode(EVENT_PHASE+PHASE_BATTLE_START)
	e5:SetRange(LOCATION_MZONE)
	e5:SetCountLimit(1,id+100)
	e5:SetOperation(s.desop)
	c:RegisterEffect(e5)

	--Opponent End Phase: return + revive
	local e6=Effect.CreateEffect(c)
	e6:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_TRIGGER_F)
	e6:SetCode(EVENT_PHASE+PHASE_END)
	e6:SetRange(LOCATION_MZONE+LOCATION_GRAVE)
	e6:SetCountLimit(1,id+200)
	e6:SetCondition(s.retcon)
	e6:SetTarget(s.rettg)
	e6:SetOperation(s.retop)
	c:RegisterEffect(e6)
end

--Only summonable by Deadly Sin
function s.splimit(e,se,sp,st)
	return se and se:GetHandler():IsCode(13131358)
end

--Unaffected by other effects
function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

--Send other monsters to GY
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local g=Duel.GetMatchingGroup(Card.IsMonster,tp,LOCATION_MZONE,0,c)
	if #g>0 then
		Duel.SendtoGrave(g,REASON_EFFECT)
	end
end

--Destroy all opponent cards
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(nil,tp,0,LOCATION_ONFIELD,nil)
	if #g>0 then
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--Opponent End Phase
function s.retcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetTurnPlayer()~=tp
end

--Umbra Witch filter
function s.filter(c,e,tp)
	return c:IsSetCard(0x7f6) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.rettg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_GRAVE,0,1,nil,e,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end

function s.retop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if c:IsRelateToEffect(e) then
		Duel.SendtoDeck(c,nil,SEQ_DECKSHUFFLE,REASON_EFFECT)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
end