--Envoy of The Moon, Repsold
local s,id,o=GetID()
function s.initial_effect(c)
	Link.AddProcedure(c,s.linkmatfilter,1,1)
	c:EnableReviveLimit()
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(EFFECT_SPSUMMON_PROC)
	e1:SetProperty(EFFECT_FLAG_UNCOPYABLE)
	e1:SetRange(LOCATION_EXTRA)
	e1:SetCondition(s.spcon)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_SINGLE)
	e2:SetCode(EFFECT_CANNOT_BE_LINK_MATERIAL)
	e2:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e2:SetCondition(s.lmcon)
	e2:SetValue(1)
	c:RegisterEffect(e2)
end
function s.linkmatfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x76b) and c:IsLevelAbove(5)
end
function s.fdmatfilter(c,tp)
	return c:IsSetCard(0x76b)
		and c:IsFacedown()
		and c:IsControler(tp)
end
function s.spcon(e,c)
	if c==nil then return true end
	local tp=c:GetControler()
	return Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
		and Duel.IsExistingMatchingCard(
			s.fdmatfilter,tp,
			LOCATION_MZONE,0,
			1,nil,tp)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp,c)

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.fdmatfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,1,
		nil,tp)

	local tc=g:GetFirst()

	if not tc then return end

	Duel.ConfirmCards(1-tp,tc)

	c:SetMaterial(g)

	Duel.SendtoGrave(tc,REASON_MATERIAL+REASON_LINK)
end
function s.lmcon(e)
	return e:GetHandler():GetTurnID()==Duel.GetTurnCount()
end