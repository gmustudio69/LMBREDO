local s,id=GetID()

function s.initial_effect(c)
	-- Fusion Material: Queen Sheba + Jubileus
	c:EnableReviveLimit()
	Fusion.AddProcMix(c,true,true,13131322,13131332)
	
	-- 1. Contact Summon Procedure (Send materials from Field to GY)
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.otcon)
	e1:SetTarget(s.ottg)
	e1:SetOperation(s.otop)
	c:RegisterEffect(e1)

	-- 2. Board Wipe: Return all opponent's cards to Deck (Unstoppable)
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TODECK)
	e2:SetType(EFFECT_TYPE_SINGLE + EFFECT_TYPE_TRIGGER_F)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE + EFFECT_FLAG_CANNOT_NEGATE)
	e2:SetOperation(s.tdop)
	c:RegisterEffect(e2)

	-- 3. Unaffected by other card effects
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_SINGLE)
	e3:SetCode(EFFECT_IMMUNE_EFFECT)
	e3:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e3:SetRange(LOCATION_MZONE)
	e3:SetValue(s.efilter)
	c:RegisterEffect(e3)

	-- 4. Recycle: Return to Extra Deck to Special Summon 2 Umbra Witches
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_IGNITION)
	e4:SetRange(LOCATION_GRAVE + LOCATION_REMOVED)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.spop)
	c:RegisterEffect(e4)
end

-- Corrected IDs: Sheba (13131322) and Jubileus (13131332)
s.SHEBA = 13131322
s.JUBILEUS = 13131332

function s.otcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCount(tp,LOCATION_MZONE)>-2
		and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_MZONE,0,1,nil,s.SHEBA)
		and Duel.IsExistingMatchingCard(Card.IsCode,tp,LOCATION_MZONE,0,1,nil,s.JUBILEUS)
end

function s.ottg(e,tp,eg,ep,ev,re,r,rp,chk,c)
	local g1=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,s.SHEBA)
	local g2=Duel.GetMatchingGroup(Card.IsCode,tp,LOCATION_MZONE,0,nil,s.JUBILEUS)
	g1:Merge(g2)
	if g1:GetCount()>=2 then
		g1:KeepAlive()
		e:SetLabelObject(g1)
		return true
	end
	return false
end

function s.otop(e,tp,eg,ep,ev,re,r,rp,c)
	local g=e:GetLabelObject()
	Duel.SendtoGrave(g,REASON_COST + REASON_MATERIAL)
	g:DeleteGroup()
end

function s.tdop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetFieldGroup(tp,0,0x3F)
	if g:GetCount()>0 then
		Duel.SendtoDeck(g,nil,2,REASON_EFFECT)
	end
end

function s.efilter(e,te)
	return te:GetOwner()~=e:GetOwner()
end

-- Umbra Witch SetID: 0x7f6
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
		and Duel.IsExistingMatchingCard(Card.IsSetCard,tp,LOCATION_GRAVE,0,2,nil,0x7f6) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if Duel.SendtoDeck(c,nil,0,REASON_EFFECT)>0 then
		local g=Duel.SelectMatchingGroup(tp,Card.IsSetCard,tp,LOCATION_GRAVE,0,2,2,nil,0x7f6)
		if g:GetCount()==2 then
			Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
		end
	end
end