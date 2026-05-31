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
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,0))
	e3:SetCategory(CATEGORY_DRAW)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	e3:SetCountLimit(1,{id,1})
	e3:SetTarget(s.tgtg)
	e3:SetOperation(s.tgop)
	c:RegisterEffect(e3)
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_REMOVE)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_REMOVE)
	e4:SetCountLimit(1,{id,2})
	e4:SetCost(s.spcost)
	e4:SetTarget(s.sptg)
	e4:SetOperation(s.ssop)
	c:RegisterEffect(e4)
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
function s.mgfilter(c)
	return c:IsFaceup()
		and c:IsCode(778804)
end
function s.moonfilter(c)
	return c:IsCode(778804)
		and not c:IsForbidden()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)

	local draw=Duel.IsPlayerCanDraw(tp,1)

	local place=Duel.IsExistingMatchingCard(
		s.moonfilter,tp,
		LOCATION_DECK,0,
		1,nil)

	if chk==0 then
		return draw or place
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_DRAW,
		nil,
		0,
		tp,
		1)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local mg=Duel.IsExistingMatchingCard(s.mgfilter,tp,LOCATION_FZONE,0,1,nil)

	if not mg then

		local tc=Duel.SelectMatchingCard(
			tp,
			s.moonfilter,
			tp,
			LOCATION_DECK,
			0,
			1,1,nil):GetFirst()

		if tc then
			Duel.MoveToField(
				tc,
				tp,
				tp,
				LOCATION_FZONE,
				POS_FACEUP,
				true)
		end

	else

		Duel.Draw(tp,1,REASON_EFFECT)
	end
	local e1=Effect.CreateEffect(e:GetHandler())
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
	e1:SetTargetRange(1,0)
	e1:SetTarget(s.splimit)
	e1:SetReset(RESET_PHASE|PHASE_END)
	Duel.RegisterEffect(e1,tp)
end
function s.costfilter(c)
	return c:IsSetCard(0x76b)
		and c:IsAbleToRemoveAsCost()
end

function s.spcost(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.costfilter,tp,
			LOCATION_MZONE,0,
			1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)

	local g=Duel.SelectMatchingCard(
		tp,
		s.costfilter,
		tp,
		LOCATION_MZONE,
		0,
		1,1,nil)

	Duel.Remove(g,POS_FACEUP,REASON_COST)
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)

	if chk==0 then
		return e:GetHandler():IsCanBeSpecialSummoned(
			e,0,tp,false,false)
	end

	Duel.SetOperationInfo(
		0,
		CATEGORY_SPECIAL_SUMMON,
		e:GetHandler(),
		1,
		0,
		0)
end
function s.ssop(e,tp,eg,ep,ev,re,r,rp)

	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then
		return
	end

	Duel.SpecialSummon(
		c,
		0,
		tp,
		tp,
		false,
		false,
		POS_FACEUP)
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return c:IsLocation(LOCATION_EXTRA)
		and not c:IsType(TYPE_LINK)
end