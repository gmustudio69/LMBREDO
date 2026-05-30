local s,id=GetID()

function s.initial_effect(c)
	-- Normal Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_TOHAND+CATEGORY_LEAVE_GRAVE+CATEGORY_SPECIAL_SUMMON+CATEGORY_POSITION)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SUMMON_SUCCESS)
	e1:SetCountLimit(1,{id,1})
	e1:SetTarget(s.thtg)
	e1:SetOperation(s.thop)
	c:RegisterEffect(e1)

	-- Special Summon
	local e2=e1:Clone()
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	c:RegisterEffect(e2)

	-- Banished
	local e3=Effect.CreateEffect(c)
	e3:SetDescription(aux.Stringid(id,1))
	e3:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e3:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e3:SetProperty(EFFECT_FLAG_DELAY)
	e3:SetCode(EVENT_REMOVE)
	e3:SetCountLimit(1,{id,2})
	e3:SetTarget(s.exctg)
	e3:SetOperation(s.excop)
	c:RegisterEffect(e3)
end
-- Moon Spell/Trap
function s.moonfilter(c)
	return c:IsSetCard(0xaaf)
		and (c:IsSpell() or c:IsTrap())
		and (c:IsAbleToHand() or c:IsSSetable())
end

-- Face-up Moon Gate
function s.mgfilter(c)
	return c:IsFaceup() and c:IsCode(778804)
end

-- Monster in hand
function s.handspfilter(c,e,tp)
	return c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEDOWN_DEFENSE)
end
function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(
			s.moonfilter,tp,LOCATION_DECK,0,1,nil)
	end
end
function s.thop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
	local g=Duel.SelectMatchingCard(tp,
		s.moonfilter,tp,LOCATION_DECK,0,1,1,nil)

	local tc=g:GetFirst()
	if not tc then return end

	local setable=tc:IsSSetable()
	local handable=tc:IsAbleToHand()

	if setable and handable then
		local op=Duel.SelectOption(tp,
			aux.Stringid(id,2), -- Add to hand
			aux.Stringid(id,3)) -- Set

		if op==0 then
			Duel.SendtoHand(tc,nil,REASON_EFFECT)
			Duel.ConfirmCards(1-tp,tc)
		else
			Duel.SSet(tp,tc)
		end
	elseif handable then
		Duel.SendtoHand(tc,nil,REASON_EFFECT)
		Duel.ConfirmCards(1-tp,tc)
	elseif setable then
		Duel.SSet(tp,tc)
	end

	-- Moon Gate bonus summon
	if Duel.IsExistingMatchingCard(
		s.mgfilter,tp,LOCATION_FZONE,0,1,nil)
		and Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(
			s.handspfilter,tp,LOCATION_HAND,0,1,nil)
		and Duel.SelectYesNo(tp,aux.Stringid(id,4)) then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

		local sg=Duel.SelectMatchingCard(tp,
			s.handspfilter,tp,LOCATION_HAND,0,1,1,nil)

		local sc=sg:GetFirst()

		if sc then
			Duel.SpecialSummon(
				sc,0,tp,tp,false,false,
				POS_FACEDOWN_DEFENSE)
		end
	end

	-- Then Set this card
	if c:IsRelateToEffect(e)
		and c:IsFaceup()
		and c:IsCanTurnSet() then
		Duel.ChangePosition(c,POS_FACEDOWN_DEFENSE)
	end
end
function s.exctg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetFieldGroupCount(1-tp,LOCATION_DECK,0)>=1
	end
end
function s.excspfilter(c,e,tp)
	return c:IsMonster()
		and c:IsCanBeSpecialSummoned(
			e,0,tp,false,false,
			POS_FACEDOWN_DEFENSE,1-tp)
end

function s.excop(e,tp,eg,ep,ev,re,r,rp)
	local p=1-tp

	local ct=math.min(5,Duel.GetFieldGroupCount(p,LOCATION_DECK,0))
	if ct==0 then return end

	Duel.ConfirmDecktop(p,ct)

	local g=Duel.GetDecktopGroup(p,ct)

	local mg=g:Filter(Card.IsMonster,nil)

	if #mg>0
		and Duel.GetLocationCount(p,LOCATION_MZONE)>0
		and Duel.SelectYesNo(tp,aux.Stringid(id,5)) then

		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)

		local sg=mg:Select(tp,1,1,nil)
		local sc=sg:GetFirst()

		if sc then
			Duel.DisableShuffleCheck()

			Duel.SpecialSummon(
				sc,0,tp,p,false,false,
				POS_FACEDOWN_DEFENSE)
		end
	end

	Duel.ShuffleDeck(p)
end