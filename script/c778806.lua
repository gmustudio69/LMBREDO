local s,id=GetID()
function s.initial_effect(c)
	-- Special Summon from hand
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetType(EFFECT_TYPE_IGNITION)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,{id,1})
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	-- Normal Summon
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_POSITION)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_CARD_TARGET+EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_SUMMON_SUCCESS)
	e2:SetCountLimit(1,{id,2})
	e2:SetTarget(s.postg)
	e2:SetOperation(s.posop)
	c:RegisterEffect(e2)

	-- Special Summon
	local e3=e2:Clone()
	e3:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Banished
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,2))
	e4:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCode(EVENT_REMOVE)
	e4:SetCountLimit(1,{id,3})
	e4:SetTarget(s.rstg)
	e4:SetOperation(s.rsop)
	c:RegisterEffect(e4)
end
function s.mgfilter(c)
	return c:IsFaceup() and c:IsCode(778804)
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.GetFieldGroupCount(tp,LOCATION_MZONE,0)
		< Duel.GetFieldGroupCount(tp,0,LOCATION_MZONE)
		or Duel.IsExistingMatchingCard(
			s.mgfilter,tp,LOCATION_FZONE,0,1,nil)
end

function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
	end
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	if not c:IsRelateToEffect(e) then return end

	Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)
end
function s.posfilter(c)
	return c:IsFaceup() and c:IsMonster() and c:IsCanTurnSet()
end

function s.postg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
	if chkc then
		return chkc:IsControler(1-tp)
			and chkc:IsLocation(LOCATION_MZONE)
			and s.posfilter(chkc)
	end

	if chk==0 then
		return Duel.IsExistingTarget(
			s.posfilter,tp,0,LOCATION_MZONE,1,nil)
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_POSCHANGE)

	local g=Duel.SelectTarget(
		tp,s.posfilter,
		tp,0,LOCATION_MZONE,
		1,1,nil)

	Duel.SetOperationInfo(0,CATEGORY_POSITION,g,2,0,0)
end

function s.posop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local tc=Duel.GetFirstTarget()

	if not c:IsRelateToEffect(e) then return end
	if not tc or not tc:IsRelateToEffect(e) then return end

	local g=Group.FromCards(c,tc)

	local fg=g:Filter(Card.IsCanTurnSet,nil)

	if #fg>0 then
		Duel.ChangePosition(fg,POS_FACEDOWN_DEFENSE)
	end
end
function s.spfilter(c,e,tp)
	return c:IsSetCard(0x76b)
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false)
end

function s.rstg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(
				s.spfilter,tp,
				LOCATION_GRAVE+LOCATION_REMOVED,
				0,1,nil,e,tp)
	end

	Duel.SetOperationInfo(
		0,CATEGORY_SPECIAL_SUMMON,
		nil,1,tp,
		LOCATION_GRAVE+LOCATION_REMOVED)
end

function s.rsop(e,tp,eg,ep,ev,re,r,rp)
	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then
		return
	end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

	local g=Duel.SelectMatchingCard(
		tp,s.spfilter,
		tp,
		LOCATION_GRAVE+LOCATION_REMOVED,
		0,
		1,1,nil,e,tp)

	local tc=g:GetFirst()

	if tc then
		Duel.SpecialSummon(
			tc,0,tp,tp,false,false,
			POS_FACEUP)
	end
end