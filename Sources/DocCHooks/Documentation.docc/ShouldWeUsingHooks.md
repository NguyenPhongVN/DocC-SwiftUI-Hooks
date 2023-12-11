# Should We Using Hooks

@Metadata {
  @PageImage(purpose: card, source: "gettingStarted-card", alt: "The profile images for a regular sloth and an ice sloth.")
}

## The answer is: I have no idea.


### If Yes.

We can:

- Matching and working with Design Pattern Architecture like TCA, Redux, MVVM...

    We can using `useLayoutEffect` or `useEffect` to subscribe state change, and perform action to Architecture.

```swift
  @HState var state = 0

  let _ = useLayoutEffect(.preserved(by: state)) {
    // send any action in here.
    // viewStore.send(_:)
  }

  let _ = useLayoutEffect(.preserved(by: viewStore.count)) {
    // update properties in hooks.
    // state = viewStore.count
  }

```

- Break down complex architecture.

    Break down logic to hooks api, itself manage state inside view.

- Simple, robust.
    
    See through example.

- Managing component state and life cycle is easier.
    
    Itself manage state


### If No.

No problem at all
