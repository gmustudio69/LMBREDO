--Love Genesis
local s,id=GetID()
local FEMALE_SET=0xf01
local MALE_SET=0xf02

function s.initial_effect(c)
	--Activate
	local e1=Effect.CreateEffect(c)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON+CATEGORY_EQUIP)
	e1:SetType(EFFECT_TYPE_ACTIVATE)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetTarget(s.target)
	e1:SetOperation(s.activate)
	c:RegisterEffect(e1)
end

-------------------------------------------------
-- Filters
-------------------------------------------------

function s.femalefilter(c,e,tp)
	return c:IsSetCard(FEMALE_SET)
		and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end

function s.malefilter(c,tp)
	return c:IsSetCard(MALE_SET)
		and c:IsMonster()
		and not c:IsForbidden()
end

-------------------------------------------------
-- Target
-------------------------------------------------

function s.target(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
			and Duel.IsExistingMatchingCard(s.femalefilter,tp,
				LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp)
			and Duel.IsExistingMatchingCard(s.malefilter,tp,
				LOCATION_HAND+LOCATION_DECK,0,1,nil,tp)
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
	Duel.SetOperationInfo(0,CATEGORY_EQUIP,nil,1,tp,LOCATION_HAND+LOCATION_DECK)
end

-------------------------------------------------
-- Activate
-------------------------------------------------

function s.activate(e,tp,eg,ep,ev,re,r,rp)

	if Duel.GetLocationCount(tp,LOCATION_MZONE)<=0 then return end

	-- Special Female
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.femalefilter,tp,
		LOCATION_HAND+LOCATION_DECK,0,1,1,nil,e,tp)
	local tc=g:GetFirst()
	if not tc then return end

	if Duel.SpecialSummon(tc,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	-- Equip Male
	-- Equip Male
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_EQUIP)
	local mg=Duel.SelectMatchingCard(tp,s.malefilter,tp,
		LOCATION_HAND+LOCATION_DECK,0,1,1,nil,tp)
	local mc=mg:GetFirst()
	if not mc then return end

	-- Send to SZONE and equip properly
	if not Duel.Equip(tp,mc,tc,true) then return end

	-- Equip limit (VERY IMPORTANT FIX)
	local e0=Effect.CreateEffect(tc)
	e0:SetType(EFFECT_TYPE_SINGLE)
	e0:SetCode(EFFECT_EQUIP_LIMIT)
	e0:SetProperty(EFFECT_FLAG_CANNOT_DISABLE)
	e0:SetReset(RESET_EVENT+RESETS_STANDARD)
	e0:SetValue(function(e,c) return c==tc end)
	mc:RegisterEffect(e0)

	-------------------------------------------------
	-- Grant Effect to Female
	-------------------------------------------------

	local e1=Effect.CreateEffect(tc)
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCountLimit(1)
	e1:SetCondition(s.childcon)
	e1:SetTarget(s.childtg)
	e1:SetOperation(s.childop)
	e1:SetReset(RESET_EVENT+RESETS_STANDARD)
	tc:RegisterEffect(e1)
end

-------------------------------------------------
-- Condition: must be equipped by Male
-------------------------------------------------

function s.childcon(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ec=c:GetEquipGroup():GetFirst()
	return ec and ec:IsSetCard(MALE_SET)
end

-------------------------------------------------
-- Target
-------------------------------------------------


function s.childtg(e,tp,eg,ep,ev,re,r,rp,chk)
	local c=e:GetHandler()
	local ec=c:GetEquipGroup():GetFirst()
	if not ec then return false end

	if chk==0 then
		return Duel.GetLocationCount(tp,LOCATION_MZONE)>1
			and Duel.IsExistingMatchingCard(
				s.childfilter,tp,
				LOCATION_HAND+LOCATION_DECK,0,1,nil,e,tp,ec:GetCode())
	end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_HAND+LOCATION_DECK)
end

-------------------------------------------------
-- Operation
-------------------------------------------------
function s.spfilter(c,class,e,tp)
	return c:IsMonster() and c:IsCanBeSpecialSummoned(e,0,tp,true,true)
		and class.listed_names and c:IsCode(table.unpack(class.listed_names))
end
function s.childop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	local ec=c:GetEquipGroup():GetFirst()
	local code=g:GetFirst():GetOriginalCode()
	local class=Duel.GetMetatable(code)
	if not ec or Duel.GetLocationCount(tp,LOCATION_MZONE)<=1 then return end

	-- Special summon equipped male
	if Duel.SpecialSummon(ec,0,tp,tp,false,false,POS_FACEUP)==0 then return end

	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	if class==nil or class.listed_names==nil then return end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,1,nil,class,e,tp)
	local tc=g:GetFirst()
	if tc then
		Duel.SpecialSummon(tc,0,tp,tp,true,true,POS_FACEUP)
		if tc:GetPreviousLocation()==LOCATION_DECK then Duel.ShuffleDeck(tp) 
		-- Lose ATK equal to original ATK
		local atk=c:GetBaseAttack()

		local e1=Effect.CreateEffect(c)
		e1:SetType(EFFECT_TYPE_SINGLE)
		e1:SetCode(EFFECT_UPDATE_ATTACK)
		e1:SetValue(-atk)
		e1:SetReset(RESET_EVENT+RESETS_STANDARD)
		c:RegisterEffect(e1)

		-- Destroy if ATK becomes 0
		if c:GetAttack()==0 then
			Duel.Destroy(c,REASON_EFFECT)
		end
		end
	end
end
