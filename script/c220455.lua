--Limit Break - HOPE
local s,id=GetID()
function s.initial_effect(c)
	-- This card is always treated as a "Limit Break" card
	-- Effect 1: Ritual Summon from Deck by tributing from hand/field/S&T
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_RELEASE)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetCountLimit(1,id)
	e1:SetTarget(s.target1)
	e1:SetOperation(s.activate1)
	c:RegisterEffect(e1)

	-- Effect 2: Ritual Summon from hand by tributing from hand/Deck/S&T
	local e2=e1:Clone()
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetTarget(s.target2)
	e2:SetOperation(s.activate2)
	e2:SetCountLimit(1,id+1)
	c:RegisterEffect(e2)
end

-- Filter for Warrior Rituals
function s.ritfilter(c,e,tp)
	return c:IsRace(RACE_WARRIOR) and c:IsRitualMonster() and c:IsLevel(7)
		and c:IsCanBeSpecialSummoned(e,SUMMON_TYPE_RITUAL,tp,true,false)
end

-- Filter for "Limit Breaker" tributes
function s.matfilter(c)
	return c:IsSetCard(0xf86) and c:IsReleasable() and c:IsMonsterCard()
end

function s.matfilter2(c)
	return c:IsSetCard(0xf86) and (c:IsReleasable() or c:IsAbleToGrave()) and c:IsMonsterCard()
end

-- Effect 1: Ritual Summon from Deck by tributing 1 from hand/field/S&T
function s.target1(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_DECK,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_SZONE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_DECK)
end

function s.activate1(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rc=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_DECK,0,1,1,nil,e,tp):GetFirst()
	if not rc then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_RELEASE)
	local mat=Duel.SelectMatchingCard(tp,s.matfilter,tp,LOCATION_HAND+LOCATION_MZONE+LOCATION_SZONE,0,1,1,nil)
	if not mat or #mat==0 then return end
	rc:SetMaterial(mat)
	Duel.Release(mat,REASON_EFFECT+REASON_RITUAL)
	Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,true,false,POS_FACEUP)
	rc:CompleteProcedure()
end

-- Effect 2: Ritual Summon from Hand by tributing 1 from hand/Deck/S&T
function s.target2(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.IsExistingMatchingCard(s.ritfilter,tp,LOCATION_HAND,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.matfilter2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_SZONE,0,1,nil)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND)
end

function s.activate2(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local rc=Duel.SelectMatchingCard(tp,s.ritfilter,tp,LOCATION_HAND,0,1,1,nil,e,tp):GetFirst()
	if not rc then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local mat=Duel.SelectMatchingCard(tp,s.matfilter2,tp,LOCATION_HAND+LOCATION_DECK+LOCATION_SZONE,0,1,1,nil)
	if not mat or #mat==0 then return end
	if mat:GetFirst():IsReleasable() then
		Duel.Release(mat,REASON_EFFECT+REASON_RITUAL)
	else
		Duel.SendtoGrave(mat,REASON_EFFECT+REASON_RITUAL)
	end
	rc:SetMaterial(mat)
	Duel.SpecialSummon(rc,SUMMON_TYPE_RITUAL,tp,tp,true,false,POS_FACEUP)
	rc:CompleteProcedure()
end
