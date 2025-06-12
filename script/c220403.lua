--Limit Breaker Aerys
local s,id=GetID()
function s.initial_effect(c)
	-- Cannot be destroyed by card effects
	local e1=Effect.CreateEffect(c)
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetRange(LOCATION_MZONE)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	-- Excavate top 3 cards, send 1 Normal Spell to GY, rest to bottom of deck
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,0))
	e2:SetCategory(CATEGORY_TOGRAVE)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetCode(EVENT_SPSUMMON_SUCCESS)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetTarget(s.excavatetg)
	e2:SetOperation(s.excavateop)
	c:RegisterEffect(e2)
	local e3=e2:Clone()
	e3:SetCode(EVENT_SUMMON_SUCCESS)
	c:RegisterEffect(e3)

	-- Set 1 "Limit Break" Trap from deck when sent to GY
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,1))
	e4:SetCategory(CATEGORY_TOHAND)
	e4:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e4:SetCode(EVENT_TO_GRAVE)
	e4:SetProperty(EFFECT_FLAG_DELAY)
	e4:SetCountLimit(1,{id,1})
	e4:SetTarget(s.settg)
	e4:SetOperation(s.setop)
	c:RegisterEffect(e4)
end

-- Filter for Normal Spell cards
function s.tgfilter(c)
	return c:IsNormalSpell() and c:IsAbleToGrave()
end

-- Excavate target
function s.excavatetg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetFieldGroupCount(tp,LOCATION_DECK,0)>=3 end
	Duel.SetTargetPlayer(tp)
	Duel.SetPossibleOperationInfo(0,CATEGORY_TOGRAVE,nil,1,tp,LOCATION_DECK)
end

function s.excavateop(e,tp,eg,ep,ev,re,r,rp)
	local p=Duel.GetChainInfo(0,CHAININFO_TARGET_PLAYER)
	local ac=3
	Duel.ConfirmDecktop(p,ac)
	local g=Duel.GetDecktopGroup(p,ac)
	if #g>0 and g:IsExists(s.tgfilter,1,nil) and Duel.SelectYesNo(p,aux.Stringid(id,0)) then
		Duel.Hint(HINT_SELECTMSG,p,HINTMSG_TOGRAVE)
		local sg=g:FilterSelect(p,s.tgfilter,1,1,nil)
		Duel.DisableShuffleCheck()
		Duel.SendtoGrave(sg,REASON_EFFECT)
		ac=ac-1
	end
	if ac>0 then
		Duel.MoveToDeckBottom(ac,tp)
		Duel.SortDeckbottom(tp,tp,ac)
	end
end


-- Filter for "Limit Break" Trap card (assumed setcode 0xf86, change if needed)
function s.setfilter(c)
	return c:IsSetCard(0xf86) and c:IsType(TYPE_TRAP) and c:IsSSetable()
end

function s.settg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,nil) end
end

function s.setop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SET)
	local g=Duel.SelectMatchingCard(tp,s.setfilter,tp,LOCATION_DECK+LOCATION_GRAVE,0,1,1,nil)
	if #g>0 then
		Duel.SSet(tp,g:GetFirst())
	end
end
