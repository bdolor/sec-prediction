with opps as (select opportunities.id,
                     (CASE
                          WHEN versions."createdAt" > statuses."createdAt" THEN versions."createdAt"
                          ELSE statuses."createdAt" END) AS "updatedAt",
                     versions.id                         as "versionsId",
                     versions."createdAt"                as "versionsCreatedAt",
                     versions."totalMaxBudget",
                     versions."minTeamMembers",
                     versions."mandatorySkills",
                     versions."optionalSkills",
                     versions."questionsWeight",
                     versions."codeChallengeWeight",
                     versions."scenarioWeight",
                     versions."priceWeight"
              from "swuOpportunities" as opportunities
                       inner join
                   "swuOpportunityStatuses" as statuses on opportunities.id = statuses.opportunity and
                                                             statuses."createdAt" = (select max("createdAt")
                                                                                       from "swuOpportunityStatuses" as statuses2
                                                                                       where statuses2.opportunity = opportunities.id
                                                                                         and statuses2.status is not null)
                       inner join
                   "swuOpportunityVersions" as versions on opportunities.id = versions.opportunity and
                                                             versions."createdAt" = (select max("createdAt")
                                                                                       from "swuOpportunityVersions" as versions2
                                                                                       where versions2.opportunity = opportunities.id)),
     props as (select proposals.opportunity,
                      proposals.id                        as "propsId",
                      (CASE
                           WHEN proposals."updatedAt" > statuses."createdAt" THEN proposals."updatedAt"
                           ELSE statuses."createdAt" END) AS "updatedAt",
                      proposals."organization",
                      proposals."anonymousProponentName",
                      proposals."challengeScore",
                      proposals."scenarioScore",
                      proposals."priceScore",
                      sum(responses.score)                as teamquestions,
                      statuses.status
               from "swuProposals" as proposals
                        INNER JOIN
                    "swuTeamQuestionResponses" as responses on responses.proposal = proposals.id
                        INNER JOIN
                    "swuProposalStatuses" as statuses
                    on proposals.id = statuses.proposal and statuses.status is not null and
                       statuses."createdAt" = (select max("createdAt")
                                                 from "swuProposalStatuses" as statuses2
                                                 where statuses2.proposal = proposals.id
                                                   and statuses2.status is not null)
               WHERE statuses.status != 'DRAFT'
               GROUP BY proposals.opportunity, proposals."anonymousProponentName", proposals.id, statuses.status,
                        statuses."createdAt"
               ORDER BY statuses."createdAt" desc),
     orgs as (select id as "orgsId", "legalName", city, region, country from organizations),
     questions as (select sum(score) as "maxQuestionScore", "opportunityVersion" as "questionsOppVersion"
                   from "swuTeamQuestions"
                   group by "opportunityVersion")
select *
from props
         inner join
     opps on props.opportunity = opps.id
         inner join
     orgs on props.organization = "orgsId"
         left join
     questions on opps."versionsId" = questions."questionsOppVersion";