--Red-Eyes Rising
local s,id=GetID()

function s.initial_effect(c)
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SEARCH+CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id,EFFECT_COUNT_CODE_OATH)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

--------------------------------------------------
--Filter
--------------------------------------------------
function s.filter(c,e,tp)
	return c:IsLevel(7)
		and (c:GetBaseAttack()==2400 or c:GetBaseDefense()==2400)
		and (c:IsAbleToHand()
		or (Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE)))
end

function s.refilter(c,e,tp)
	return c:IsSetCard(0x3b)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

--------------------------------------------------
--Target
--------------------------------------------------
function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
	if chk==0 then return Duel.IsExistingMatchingCard(s.filter,tp,LOCATION_DECK,0,1,nil,e,tp,ft)
		and Duel.IsExistingMatchingCard(Card.IsDiscardable,tp,LOCATION_HAND,0,1,e:GetHandler(),REASON_EFFECT) end
	Duel.SetOperationInfo(0,CATEGORY_HANDES,nil,0,tp,1)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOHAND,nil,1,tp,LOCATION_DECK)
	Duel.SetPossibleOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

--------------------------------------------------
--Operation
--------------------------------------------------
function s.activate(e,tp,eg,ep,ev,re,r,rp)
	if Duel.DiscardHand(tp,nil,1,1,REASON_EFFECT|REASON_DISCARD,nil)>0 then
		local ft=Duel.GetLocationCount(tp,LOCATION_MZONE)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_ATOHAND)
		local g=Duel.SelectMatchingCard(tp,s.filter,tp,LOCATION_DECK,0,1,1,nil,e,tp,ft)
		local sc=g:GetFirst()
		if sc then
			Duel.BreakEffect()
			aux.ToHandOrElse(sc,tp,function(c)
				return sc:IsCanBeSpecialSummoned(e,0,tp,false,false,POS_FACEUP_DEFENSE) and ft>0 end,
			function(c)
				Duel.SpecialSummon(sc,0,tp,tp,false,false,POS_FACEUP_DEFENSE) end,
			aux.Stringid(id,1))
		end
	Duel.BreakEffect()
	if sc:IsOriginalCode(74677422) then
		if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

		if Duel.IsExistingMatchingCard(s.refilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp) then

			Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
			local sg=Duel.SelectMatchingCard(tp,s.refilter,tp,LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)

			if #sg>0 then
				Duel.SpecialSummon(sg:GetFirst(),0,tp,tp,false,false,POS_FACEUP)
			end

		end
	end
	end
end