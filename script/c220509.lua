--Hana - The Wind Spirit
local s,id=GetID()
function s.initial_effect(c)
	--Special Summon + Link Summon
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e1:SetType(EFFECT_TYPE_QUICK_O)
	e1:SetCode(EVENT_FREE_CHAIN)
	e1:SetRange(LOCATION_HAND)
	e1:SetCountLimit(1,id)
	e1:SetCondition(s.spcon)
	e1:SetTarget(s.sptg)
	e1:SetOperation(s.spop)
	c:RegisterEffect(e1)

	--Search or send to GY
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_TOHAND+CATEGORY_TOGRAVE+CATEGORY_SEARCH)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_BE_MATERIAL)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.thcon)
	e2:SetTarget(s.thtg)
	e2:SetOperation(s.thop)
	c:RegisterEffect(e2)
end

-- Check if you control "<Limit Breaker> Kazari"
function s.cfilter(c)
	return c:IsFaceup() and c:IsCode(220450) -- replace with Kazari's ID
end
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return Duel.IsExistingMatchingCard(s.cfilter,tp,LOCATION_MZONE,0,1,nil)
end

-- Special Summon target
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return e:GetHandler():IsCanBeSpecialSummoned(e,0,tp,false,false) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,e:GetHandler(),1,0,0)
end

-- Filter for WIND Warrior Link Monsters
function s.linkfilter(c,e,tp)
	return c:IsRace(RACE_WARRIOR)
		and c:IsType(TYPE_LINK)
		and c:IsLinkSummonable(nil,nil)
end

function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	if c:IsRelateToEffect(e) and Duel.SpecialSummon(c,0,tp,tp,false,false,POS_FACEUP)>0 then
		Duel.BreakEffect()
		-- Link Summon
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
		local g=Duel.GetMatchingGroup(s.linkfilter,tp,LOCATION_EXTRA,0,nil,e,tp)
		if #g>0 then
			local lc=g:Select(tp,1,1,nil):GetFirst()
			Duel.LinkSummon(tp,lc,c)
		end
	end
end

-- Trigger when used as Link Material
function s.thcon(e,tp,eg,ep,ev,re,r,rp)
	return r==REASON_LINK
end

-- Spirit or Kazari filter
function s.thfilter(c)
	return c:IsRace(RACE_SPIRIT) or c:IsCode(220450) -- replace Kazari ID
end

function s.thtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.thfilter,tp,LOCATION_DECK,0,1,nil) end
end

function s.thop(e,tp,eg,ep,ev,re,r,rp)
		Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_OPERATECARD)
		local g=Duel.SelectMatchingCard(tp,s.thfilter,tp,LOCATION_DECK,0,1,1,nil)
		local tc=g:GetFirst()
		if tc then
			Duel.Hint(HINT_SELECTMSG,tp,aux.Stringid(id,2))
			local op=Duel.SelectOption(tp,aux.Stringid(id,3),aux.Stringid(id,4))
			if op==0 then
				Duel.SendtoHand(tc,nil,REASON_EFFECT)
				Duel.ConfirmCards(1-tp,tc)
			else
				Duel.SendtoGrave(tc,REASON_EFFECT)
			end
		end
end