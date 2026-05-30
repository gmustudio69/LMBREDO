local s,id=GetID()

function s.initial_effect(c)
	-- Link Summon
	Link.AddProcedure(c,aux.FilterBoolFunctionEx(Card.IsType,TYPE_EFFECT),2)
	c:EnableReviveLimit()

	-- Special Summon procedure from Extra Deck
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
end

-- "Mysthich" monster
function s.mysthichfilter(c)
	return c:IsSetCard(0xb67)
end

-- Face-down monster
function s.fdfilter(c)
	return c:IsFacedown() and c:IsMonster()
end

function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()

	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(s.mysthichfilter,tp,LOCATION_MZONE,0,1,nil)
		and Duel.IsExistingMatchingCard(s.fdfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil)
end

function s.spfilter(c,tp)
	return s.mysthichfilter(c)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp,c)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g1=Duel.SelectMatchingCard(tp,s.mysthichfilter,tp,LOCATION_MZONE,0,1,1,nil)
	local mc=g1:GetFirst()

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g2=Duel.SelectMatchingCard(tp,s.fdfilter,tp,
		LOCATION_MZONE,LOCATION_MZONE,1,1,mc)
	local fc=g2:GetFirst()

	-- Reveal the Mysthich monster if face-down
	if mc:IsFacedown() then
		Duel.ConfirmCards(1-tp,mc)
	end

	local sg=Group.FromCards(mc,fc)
	Duel.SendtoGrave(sg,REASON_MATERIAL+REASON_LINK)

	c:SetMaterial(sg)
end